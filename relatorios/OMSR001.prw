#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

Static nPadLeft   := 0 //Alinhamento a Esquerda
Static nPadRight  := 1 //Alinhamento a Direita
Static nPadCenter := 2 //Alinhamento Centralizado

/*/{Protheus.doc} OMSR01
Impressão de Romaneio
@type function
@version
@author TOTVS Nordeste
@since 06/01/2025
@return 
/*/
User Function OMSR01()
	RptStatus({|| GeraRel()}, "Aguarde...", "Executando rotina...")
Return 

Static Function GeraRel()

Local oPanel, oCombo
Local cCargaDe  := Space(FWTamSX3("DAK_COD")[1])
Local cCargaAte := Space(FWTamSX3("DAK_COD")[1])
Local oFont     := TFont():New('Arial Black',,-23,.T.)
Local cQry      := ""
Local cAuxCarga := ""
Local nAtual 	:= 0
Local nTotal 	:= 0
Local aCombo    := {"N - Nao","S - Sim"}

Private nLin     := 40
Private nCol     := 10
Private cNomeEmp := Alltrim(FWSM0Util():GetSM0Data( cEmpAnt , cFilAnt , { "M0_FULNAME" } )[1][2])
Private cPathPDF := ""
Private oDialog  := Nil 
Private oPrint   := Nil 
Private oFont10  := TFont():New( "Arial",,11,,.F.,,,,,.F. )
Private oFont14  := TFont():New( "Arial",,14,,.F.,,,,,.F. )
Private oFont14B := TFont():New( "Arial",,14,,.T.,,,,,.F. )
Private lBtOK    := .F.
Private nPosUnid := 13
Private nPosDesc := 50
Private nPosQuan := 310
Private nPosLote := 380
Private nPosVali := 470
Private nPagina  := 0
Private _cAlias  := GetNextAlias()
Private aQtdCar  := {}
Private cCombo   := ""

	oDialog := FWDialogModal():New()
	oDialog:SetBackground( .T. ) 
	oDialog:SetTitle( 'Informe o código da Carga' )
	oDialog:SetSize( 150, 160 )
	oDialog:EnableFormBar( .T. )
	oDialog:SetCloseButton( .T. )
	oDialog:SetEscClose( .T. )
	oDialog:CreateDialog()
	oDialog:CreateFormBar()
	oDialog:addCloseButton(Nil, "Fechar")
    oDialog:addOkButton({|| fButtomOk() },'Confirmar')

	oPanel := oDialog:GetPanelMain()
			oTSay  := TSay():New(10,5,{|| "Carga De:"},oPanel,,oFont,,,,.T.,,,110,100,,,,,,.T.)
            @ 008,080 MSGET cCargaDe SIZE 050,020 FONT oFont OF oPanel F3 "DAK" PIXEL
			oTSay  := TSay():New(40,5,{|| "Carga Ate:"},oPanel,,oFont,,,,.T.,,,110,100,,,,,,.T.)
            @ 038,080 MSGET cCargaAte SIZE 050,020 FONT oFont OF oPanel F3 "DAK" PIXEL
			oTSay  := TSay():New(70,5,{|| "Conf. Cega?"},oPanel,,oFont,,,,.T.,,,110,100,,,,,,.T.)
            oCombo := TComboBox():New(095,085,{|u|iif(PCount()>0,cCombo:=u,cCombo)},aCombo,070,040,,,{||},,,,.T.,oFont,,,,,,,,'cCombo')
	oDialog:Activate()

	If lBtOK .And. !Empty(cCargaAte)

		// Inicialize o objeto desta forma
		oPrint:=FWMSPrinter():New(FWTimeStamp(1),IMP_PDF, .F., , .T.)
		oPrint:SetResolution(72)
		oPrint:SetPortrait()
		oPrint:SetPaperSize(DMPAPER_A4)
		oPrint:SetMargin(60,60,60,60) // nEsquerda, nSuperior, nDireita, nInferior
		oPrint:cPathPDF := GetTempPath()

		cQry := " SELECT DISTINCT SUM(SC9.C9_QTDLIB) AS C9_QTDLIB, SC9.C9_CARGA "
		cQry += " FROM " + RetSQLName('SC9') + " SC9 "
		cQry += " WHERE SC9.D_E_L_E_T_ <> '*' "
		cQry += " 	AND SC9.C9_FILIAL  = '" + xFilial("SC9") + "'"
		cQry += "   AND SC9.C9_CARGA <> '' "
		cQry += "   AND SC9.C9_CARGA BETWEEN '" + cCargaDe + "' AND '" + cCargaAte + "'"
		cQry += " GROUP BY SC9.C9_CARGA "
		cQry += " ORDER BY SC9.C9_CARGA "
		cQry := ChangeQuery(cQry)
  		IF Select(_cAlias) <> 0
          (_cAlias)->(DbCloseArea())
      	EndIf
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),_cAlias,.T.,.T.)
		
		While (_cAlias)->(!EoF())
			aAdd(aQtdCar,{(_cAlias)->C9_CARGA,(_cAlias)->C9_QTDLIB})
		(_cAlias)->(DbSkip())
		End
		IF Select(_cAlias) <> 0
          (_cAlias)->(DbCloseArea())
      	EndIf
		
		cQry := " SELECT DISTINCT SC9.C9_PRODUTO, SB1.B1_DESC, SB1.B1_UM, SUM(SC9.C9_QTDLIB) AS C9_QTDLIB, SC9.C9_LOTECTL, SC9.C9_CARGA, SB8.B8_DTVALID "
		cQry += " FROM " + RetSQLName('SC9') + " SC9 "
		cQry += " INNER JOIN " + RetSQLName('SB1') + " SB1 ON SB1.B1_COD = SC9.C9_PRODUTO AND SB1.B1_FILIAL = '" + xFilial("SB1") + "'"
		cQry += " INNER JOIN " + RetSQLName('SB8') + " SB8 ON SB8.B8_LOTECTL = SC9.C9_LOTECTL AND SB8.B8_DTVALID = SC9.C9_DTVALID AND SB8.B8_LOCAL = SC9.C9_LOCAL AND SB8.B8_FILIAL = '" + xFilial("SB8") + "'"
		cQry += " WHERE SC9.D_E_L_E_T_ <> '*' "
		cQry += " 	AND SB1.D_E_L_E_T_ <> '*' "
		cQry += " 	AND SB8.D_E_L_E_T_ <> '*' "
		cQry += " 	AND SC9.C9_FILIAL  = '" + xFilial("SC9") + "'"
		cQry += "   AND SC9.C9_CARGA <> '' "
		cQry += "   AND SC9.C9_CARGA BETWEEN '" + cCargaDe + "' AND '" + cCargaAte + "'"
		cQry += " GROUP BY SC9.C9_PRODUTO, SB1.B1_DESC, SB1.B1_UM, SC9.C9_LOTECTL, SC9.C9_CARGA, SB8.B8_DTVALID "
		cQry += " ORDER BY SC9.C9_CARGA, SC9.C9_PRODUTO, SC9.C9_LOTECTL "
		cQry := ChangeQuery(cQry)
  		IF Select(_cAlias) <> 0
          (_cAlias)->(DbCloseArea())
      	EndIf
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),_cAlias,.T.,.T.)

		Count To nTotal
    	SetRegua(nTotal)

		If nTotal <= 0
			FWAlertWarning("Nenhum dado encontrado.","TOTVS")
			IF Select(_cAlias) <> 0
				(_cAlias)->(DbCloseArea())
			EndIf
			Return
		EndIF 

		(_cAlias)->(DbGoTop())

		While (_cAlias)->(!EoF())
			
			nAtual++
        	IncRegua()

			Do Case
				Case Empty(cAuxCarga)
					
					nLin := 40
					cAuxCarga := (_cAlias)->C9_CARGA
					
					fnCabec((_cAlias)->C9_CARGA)
					fnRodape((_cAlias)->C9_CARGA)			
				Case cAuxCarga <> (_cAlias)->C9_CARGA
					
					nLin := 40
					cAuxCarga := (_cAlias)->C9_CARGA

					fnCabec((_cAlias)->C9_CARGA)
					fnRodape((_cAlias)->C9_CARGA)
			EndCase

			If nLin+80 >= 800
				nLin := 40
				fnCabec((_cAlias)->C9_CARGA)
				fnRodape((_cAlias)->C9_CARGA)
			EndIF

			fnItens() 
			
		(_cAlias)->(DbSkip())
		End

		IF Select(_cAlias) <> 0
			(_cAlias)->(DbCloseArea())
		EndIf

		oPrint:EndPage()
		oPrint:Preview()
		ms_flush()
	EndIF 	

Return

/*/{Protheus.doc} fButtomOk
    Botão OK 
/*/
Static Function fButtomOk()
    lBtOK := .T.
    oDialog:DeActivate()
Return

/*/{Protheus.doc} fnCabec
    Imprime o cabeçalho do relatório
/*/
Static Function fnCabec(pCarga)
	
	nPagina += 1

	oPrint:StartPage()
	oPrint:Say (nLin, nCol, Alltrim(cNomeEmp) 			   				, oFont14B,400,07,,nPadCenter,)
	nLin += 10
	oPrint:Say (nLin, nCol, "Romaneio de Entrega" 		   		 		, oFont14B,400,07,,nPadCenter,)
	nLin -= 10
	oPrint:Say (nLin, nPosLote+60, "Emissão:  "  + DToC(dDataBase)		, oFont10 ,480,07,,nPadRight,)
	nLin += 10
	oPrint:Say (nLin, nPosLote+60, "Página:     " + cValToChar(nPagina)	, oFont10 ,480,07,,nPadRight,)
	nLin += 10
	oPrint:Say (nLin, nPosLote+60, "Hora:       " + Time()				, oFont10 ,480,07,,nPadRight,)
	nLin += 10
	oPrint:Say (nLin, nPosLote+60, "Usuário:   " + cUserName			, oFont10 ,480,07,,nPadRight,)

	nLin += 15
	oPrint:Box(nLin,nCol,nLin+25,nCol+540)
	nLin += 15
	//oPrint:Say (nLin, nPosUnid, "ASSAI ARAPIRACA"						, oFont10 ,480,07,,nPadRight,)
	oPrint:Say (nLin, nPosLote+60, "Nº:   " + pCarga					, oFont14B ,480,07,,nPadRight,)

	nLin += 20
	oPrint:Box(nLin,nCol,nLin+20,nCol+540)
	nLin += 15
	oPrint:Say (nLin, nPosUnid, "UN"									, oFont14B ,480,07,,nPadRight,)
	oPrint:Say (nLin, nPosDesc, "DESCRICAO DO PRODUTO"					, oFont14B ,480,07,,nPadRight,)
	oPrint:Say (nLin, nPosQuan, "QUANT"									, oFont14B ,480,07,,nPadRight,)
	oPrint:Say (nLin, nPosLote, "LOTE"									, oFont14B ,480,07,,nPadRight,)
	oPrint:Say (nLin, nPosVali, "VALIDADE"								, oFont14B ,480,07,,nPadRight,)

	nLin += 20

Return

/*/{Protheus.doc} fnItens
    Imprime os Itens do relatório
/*/
Static Function fnItens()
Local cPictQtd  := "@E 99,999,999,999.99"

	oPrint:Say (nLin, nPosUnid, AllTrim((_cAlias)->B1_UM)							, oFont14 ,200,07,,nPadRight,)
	oPrint:Say (nLin, nPosDesc, Upper(AllTrim((_cAlias)->B1_DESC))					, oFont14 ,200,07,,nPadRight,)
	If SubStr(cCombo,1,1) == "N"
	oPrint:Say (nLin, nPosQuan, AllTrim(AllToChar((_cAlias)->C9_QTDLIB,cPictQtd))	, oFont14 ,200,07,,nPadRight,)
	EndIF 
	oPrint:Say (nLin, nPosLote, AllTrim((_cAlias)->C9_LOTECTL)						, oFont14 ,200,07,,nPadRight,)
	oPrint:Say (nLin, nPosVali, DToC(SToD((_cAlias)->B8_DTVALID))					, oFont14 ,200,07,,nPadRight,)
	nLin += 10
	oPrint:Say (nLin, nPosUnid, REPLICATE("-", 148)									, oFont14 ,200,07,,nPadRight,)
	nLin += 10

Return

/*/{Protheus.doc} fnCabec
    Imprime o rodape do relatório
/*/
Static Function fnRodape(pCarga)
Local nLinAux  := 760
Local cPictQtd := "@E 99,999,999,999.99" 
Local nPosCar  := aScan(aQtdCar,{|x| AllTrim(x[01]) == AllTrim(pCarga)})
Local nTotalCX := aQtdCar[nPosCar][2]
	
	oPrint:Box(nLinAux,nCol,nLinAux+60,nCol+540)
	nLinAux += 20
	If SubStr(cCombo,1,1) == "N"
	oPrint:Say (nLinAux, nPosQuan, "QUANTIDADE TOTAL: "+ AllTrim(AllToChar(nTotalCX,cPictQtd))	, oFont14 ,200,07,,nPadRight,)
	Else
	oPrint:Say (nLinAux, nPosQuan, "QUANTIDADE TOTAL: ______________"							, oFont14 ,200,07,,nPadRight,)
	EndIF 
	nLinAux += 30
	oPrint:Say (nLinAux, nPosUnid, "ASS. CONFERENTE: _____________________________"				, oFont14 ,500,07,,nPadRight,)
	oPrint:Say (nLinAux, nPosQuan, "QTD CAIXA: ______________________"							, oFont14 ,200,07,,nPadRight,)

Return
