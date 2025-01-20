//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

//Variaveis
Static nPadLeft   := 0                                                                     //Alinhamento a Esquerda
Static nPadRight  := 1                                                                     //Alinhamento a Direita
Static nPadCenter := 2                                                                     //Alinhamento Centralizado
Static nPosCod    := 0000                                                                  //Posição Inicial da Coluna de Código do Produto
Static nPosDesc   := 0000                                                                  //Posição Inicial da Coluna de Descrição
Static nPosNCM    := 0000                                                                  //Posição Inicial da Coluna de NCM
Static nPosUnid   := 0000                                                                  //Posição Inicial da Coluna de Unidade de Medida
Static nPosQuan   := 0000                                                                  //Posição Inicial da Coluna de Quantidade
Static nPosVUni   := 0000                                                                  //Posição Inicial da Coluna de Valor Unitario
Static nPosVTot   := 0000                                                                  //Posição Inicial da Coluna de Valor Total
Static nPosEnt    := 0000                                                                  //Posição Inicial da Coluna de Data de Entrega

Static nTamFundo  := 15                                                                    //Altura de fundo dos blocos com título
Static cEmpEmail  := Alltrim(SuperGetMV("MV_X_EMAIL", .F., "email@empresa.com.br"))        //Parímetro com o e-Mail da empresa
Static cEmpSite   := Alltrim(SuperGetMV("MV_X_HPAGE", .F., "http://www.empresa.com.br"))   //Parímetro com o site da empresa
Static nCorAzul   := RGB(89, 111, 117)                                                     //Cor Azul usada nos Títulos
Static cNomeFont  := "Arial"                                                               //Nome da Fonte Padrío
Static oFontDet   := Nil                                                                   //Fonte utilizada na Impressão dos itens
Static oFontDetN  := Nil                                                                   //Fonte utilizada no cabeÃ§alho dos itens
Static oFontRod   := Nil                                                                   //Fonte utilizada no rodape da Página
Static oFontTit   := Nil                                                                   //Fonte utilizada no Título das seções
Static oFontCab   := Nil                                                                   //Fonte utilizada na Impressão dos textos dentro das seções
Static oFontCabN  := Nil                                                                   //Fonte negrita utilizada na Impressão dos textos dentro das seções
Static cMaskPad   := "@E 999,999.99"                                                       //Míscara padrío de valor
Static cMaskTel   := "@R (99)99999999"                                                    //Míscara de telefone / fax
Static cMaskCNPJ  := "@R 99.999.999/9999-99"                                               //Máscara de CNPJ
Static cMaskCEP   := "@R 99999-999"                                                        //Máscara de CEP
Static cMaskCPF   := "@R 999.999.999-99"                                                   //Máscara de CPF
Static cMaskQtd   := PesqPict("SCK", "CK_QTDVEN")                                          //Máscara de quantidade
Static cMaskPrc   := PesqPict("SCK", "CK_VALOR")                                          //Máscara de preço
Static cMaskVlr   := PesqPict("SCK", "CK_VALOR")                                           //Máscara de valor
// Static cMaskFrete := PesqPict("SCJ", "CJ_FRETE")                                           //Máscara de frete


/*/{Protheus.doc} zROrcamento
Impressão do orçamento (PDF)
@type function
@author Atilio
@since 19/06/2016
@version 1.0
	@example
	u_zROrcamento()
/*/

User Function zROrcamento()
	Local aArea      := GetArea()
	Local aAreaCJ    := SCJ->(GetArea())
	Local aPergs     := {}
	Local aRetorn    := {}
	Local oProcess   := Nil

	//Variaveis usadas nas outras funçães
	Private cLogoEmp := fLogoEmp()
	Private cOrcDe   := SCJ->CJ_NUM
	Private cOrcAt   := SCJ->CJ_NUM
	// Private cLayout  := "1"
	// Private cTipoBar := "3"
	Private cImpDupl := "1"
	Private cZeraPag := "1"

	//Adiciona os parâmetro para a pergunta
	aAdd(aPergs, {1, "Orcamento De",  cOrcDe, "", ".T.", "SJC", ".T.", 80, .T.})
	aAdd(aPergs, {1, "Orcamento Ate", cOrcAt, "", ".T.", "SJC", ".T.", 80, .T.})

	//Se a pergunta for confirmada
	If ParamBox(aPergs, "Informe os parâmetro", @aRetorn, , , , , , , , .F., .F.)
		cOrcDe   := aRetorn[1]
		cOrcAt   := aRetorn[2]

		//Chama o processamento do relatório
		oProcess := MsNewProcess():New({|| fMontaRel(@oProcess) }, "Impressão Pedidos de Venda", "Processando", .F.)
		oProcess:Activate()
	EndIf

	RestArea(aAreaCJ)
	RestArea(aArea)
Return

Static Function fMontaRel(oProc)
	//Variaveis usada no controle das ríguas
	Local nTotIte       := 0
	Local nItAtu        := 0
	Local nTotOrc       := 0
	Local nOrcAtu       := 0
	//Consultas SQL
	Local cQryOrc       := ""
	Local cQryIte       := ""
	//Valores de Impostos
	Local nBasICM       := 0
	Local nValICM       := 0
	Local nValIPI       := 0
	Local nAlqICM       := 0
	Local nAlqIPI       := 0
	Local nValSol       := 0
	Local nBasSol       := 0
	Local nPrcUniSol    := 0
	Local nTotSol       := 0
	//Variaveis do relatório
	Local cNomeRel      := "Pedido_venda_"+FunName()+"_"+RetCodUsr()+"_"+dToS(Date())+"_"+StrTran(Time(), ":", "")
	Private oPrintPvt
	Private cHoraEx     := Time()
	Private nPagAtu     := 1
	Private aDuplicatas := {}
	//Linhas e colunas
	Private nLinAtu     := 0
	Private nLinFin     := 580
	Private nColIni     := 010
	Private nColFin     := 820
	Private nColMeio    := (nColFin-nColIni)/2
	//Totalizadores
	Private nTotFrete   := 0
	Private nValorTot   := 0
	Private nTotalST    := 0
	Private nTotVal     := 0
	Private nTotIPI     := 0
	Private nDesconto   := 0
	
	DbSelectArea("SB1")
	SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
	SB1->(DbGoTop())
	DbSelectArea("SCJ")
	
	//Criando o objeto de Impressao
	oPrintPvt := FWMSPrinter():New(cNomeRel, IMP_PDF, .F., /*cStartPath*/, .T., , @oPrintPvt, , , , , .T.)
	oPrintPvt:cPathPDF := GetTempPath()
	oPrintPvt:SetResolution(72)
	oPrintPvt:SetLandscape()
	oPrintPvt:SetPaperSize(DMPAPER_A4)
	oPrintPvt:SetMargin(10, 10, 10, 10)
	
//Selecionando os Orcamentos
	cQryOrc := " SELECT "                                        + CRLF
	cQryOrc += "    CJ_FILIAL, "                                 + CRLF
	cQryOrc += "    CJ_NUM, "                                    + CRLF
	cQryOrc += "    CJ_EMISSAO, "                                + CRLF
	cQryOrc += "    CJ_CLIENTE, "                                + CRLF
	cQryOrc += "    CJ_LOJA, "                                	 + CRLF
	cQryOrc += "    ISNULL(A1_NOME, '') AS A1_NOME, "       	 + CRLF
	cQryOrc += "    ISNULL(A1_NREDUZ, '') AS A1_NREDUZ, "      	 + CRLF
	cQryOrc += "    ISNULL(A1_PESSOA, '') AS A1_PESSOA, "        + CRLF
	cQryOrc += "    ISNULL(A1_CGC, '') AS A1_CGC, "              + CRLF
	cQryOrc += "    ISNULL(A1_END, '') AS A1_END, "              + CRLF
	cQryOrc += "    ISNULL(A1_BAIRRO, '') AS A1_BAIRRO, "        + CRLF
	cQryOrc += "    ISNULL(A1_MUN, '') AS A1_MUN, "              + CRLF
	cQryOrc += "    ISNULL(A1_EST, '') AS A1_EST, "              + CRLF
	cQryOrc += "    ISNULL(A1_DDD, '') AS A1_DDD, "       		 + CRLF
	cQryOrc += "    ISNULL(A1_TEL, '') AS A1_TEL, "       		 + CRLF
	cQryOrc += "    ISNULL(A1_EMAIL, '') AS A1_EMAIL, "       	 + CRLF
	cQryOrc += "    CJ_CONDPAG, "                                + CRLF 
	cQryOrc += "    ISNULL(E4_DESCRI, '') AS E4_DESCRI, "        + CRLF // SELECT
	cQryOrc += "    SCJ.R_E_C_N_O_ AS CJREC "                    + CRLF // CLIENTE
	cQryOrc += " FROM "                                          + CRLF
	cQryOrc += "    "+RetSQLName("SCJ")+" SCJ "                  + CRLF
	cQryOrc += "    LEFT JOIN "+RetSQLName("SA1")+" SA1 ON ( "   + CRLF
	cQryOrc += "        A1_FILIAL   = '"+FWxFilial("SA1")+"' "   + CRLF
	cQryOrc += "        AND A1_COD  = SCJ.CJ_CLIENTE "           + CRLF
	cQryOrc += "        AND A1_LOJA = SCJ.CJ_LOJA "           	 + CRLF
	cQryOrc += "        AND SA1.D_E_L_E_T_ = ' ' "               + CRLF
	cQryOrc += "    ) "                                          + CRLF
	cQryOrc += "    LEFT JOIN "+RetSQLName("SE4")+" SE4 ON ( "   + CRLF // CONDICAO DE PAGAMENTO
	cQryOrc += "        E4_FILIAL     = '"+FWxFilial("SE4")+"' " + CRLF
	cQryOrc += "        AND E4_CODIGO = SCJ.CJ_CONDPAG "         + CRLF
	cQryOrc += "        AND SE4.D_E_L_E_T_ = ' ' "               + CRLF
	cQryOrc += "    ) "                                          + CRLF

	cQryOrc += " WHERE "                                         + CRLF
	cQryOrc += "    CJ_FILIAL   = '"+FWxFilial("SCJ")+"' "       + CRLF
	cQryOrc += "    AND CJ_NUM >= '"+cOrcDe+"' "                 + CRLF
	cQryOrc += "    AND CJ_NUM <= '"+cOrcAt+"' "                 + CRLF
	cQryOrc += "    AND SCJ.D_E_L_E_T_ = ' ' "                   + CRLF
	TCQuery cQryOrc New Alias "QRY_ORC"
	TCSetField("QRY_ORC", "CJ_EMISSAO", "D")
	Count To nTotOrc
	oProc:SetRegua1(nTotOrc)
	
	//Somente se houver Pedidos
	If nTotOrc != 0
	
		//Enquanto houver Pedidos
		QRY_ORC->(DbGoTop())
		While ! QRY_ORC->(EoF())
			If cZeraPag == "1"
				nPagAtu := 1
			EndIf
			nOrcAtu++
			oProc:IncRegua1("Processando o Pedido "+cValToChar(nOrcAtu)+" de "+cValToChar(nTotOrc)+"...")
			oProc:SetRegua2(1)
			oProc:IncRegua2("...")
			
			//Imprime o cabecalho
			fImpCab()
			
			//Seleciona os itens do Pedido
			cQryIte := " SELECT "                                      + CRLF
			cQryIte += "    CK_PRODUTO, "                              + CRLF
			cQryIte += "    ISNULL(B1_DESC, '') AS B1_DESC, "          + CRLF
			cQryIte += "    ISNULL(B1_POSIPI, '') AS B1_POSIPI, "      + CRLF
			cQryIte += "    CK_UM, "                                   + CRLF
			cQryIte += "    CK_ENTREG, "                               + CRLF
			cQryIte += "    CK_QTDVEN, "                               + CRLF
			cQryIte += "    CK_PRCVEN, "                               + CRLF
			cQryIte += "    CK_VALOR "                                 + CRLF
			cQryIte += " FROM "                                        + CRLF
			cQryIte += "    "+RetSQLName("SCK")+" SCK "                + CRLF
			cQryIte += "    LEFT JOIN "+RetSQLName("SB1")+" SB1 ON ( " + CRLF
			cQryIte += "        B1_FILIAL = '"+FWxFilial("SB1")+"' "   + CRLF
			cQryIte += "        AND B1_COD = SCK.CK_PRODUTO "          + CRLF
			cQryIte += "        AND SB1.D_E_L_E_T_ = ' ' "             + CRLF
			cQryIte += "    ) "                                        + CRLF
			cQryIte += " WHERE "                                       + CRLF
			cQryIte += "    CK_FILIAL = '"+FWxFilial("SCK")+"' "       + CRLF
			cQryIte += "    AND CK_NUM = '"+QRY_ORC->CJ_NUM+"' "       + CRLF
			cQryIte += "    AND SCK.D_E_L_E_T_ = ' ' "                 + CRLF
			cQryIte += " ORDER BY "                                    + CRLF
			cQryIte += "    CK_ITEM "                                  + CRLF
			TCQuery cQryIte New Alias "QRY_ITE"
			TCSetField("QRY_ITE", "CK_ENTREG", "D")
			Count To nTotIte
			nValorTot := 0
			oProc:SetRegua2(nTotIte)
			
			//Enquanto houver itens
			QRY_ITE->(DbGoTop())
			While ! QRY_ITE->(EoF())
				nItAtu++
				oProc:IncRegua2("Calculando impostos - item "+cValToChar(nItAtu)+" de "+cValToChar(nTotIte)+"...")
  
				// nValSol    := (MaFisRet(nItAtu,"IT_VALSOL") / QRY_ITE->CK_QTDVEN) 
				// nTotSol    := nPrcUniSol * QRY_ITE->CK_QTDVEN


				//Imprime os dados
			
					oPrintPvt:SayAlign(nLinAtu, nPosCod, QRY_ITE->CK_PRODUTO,                                oFontDet, 200, 35, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosDesc, QRY_ITE->B1_DESC,                                  oFontDet, 200, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosUnid, QRY_ITE->CK_UM,                                    oFontDet, 030, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosNCM , QRY_ITE->B1_POSIPI,                                oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosQuan, Alltrim(Transform(QRY_ITE->CK_QTDVEN, cMaskQtd)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVUni, Alltrim(Transform(QRY_ITE->CK_PRCVEN, cMaskPrc)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVTot, Alltrim(Transform(QRY_ITE->CK_VALOR, cMaskVlr)),   oFontDet, 050, 07, , nPadLeft,)
					// oPrintPvt:SayAlign(nLinAtu, nPosSTVl, Alltrim(Transform(nPrcUniSol, cMaskPrc)),          oFontDet, 050, 07, , nPadLeft,)
					// oPrintPvt:SayAlign(nLinAtu, nPosSTTo, Alltrim(Transform(nTotSol, cMaskVlr)),             oFontDet, 050, 07, , nPadLeft,) 
					// oPrintPvt:SayAlign(nLinAtu, nPosAIcm, Alltrim(Transform(nAlqICM, cMaskPad)),             oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosEnt , DToC(QRY_ITE->CK_ENTREG),                          oFontDet, 050, 07, , nPadLeft,)
				
				nLinAtu += 10
				
				//Se por acaso atingiu o limite da pagina, finaliza, e começa uma nova pagina
				If nLinAtu >= nLinFin
					fImpRod()
					fImpCab()
				EndIf
				
				nValorTot += QRY_ITE->CK_VALOR
				QRY_ITE->(DbSkip())
			EndDo
			// nTotFrete := MaFisRet(, "NF_FRETE")
			nTotVal := MaFisRet(, "NF_TOTAL")
			// fMontDupl()
			QRY_ITE->(DbCloseArea())
			MaFisEnd()
			
			//Imprime o Total do Pedido
			fImpTot()
			
			//Se tiver mensagem da observacao
			// If !Empty(QRY_ORC->CJ_MENNOTA)
			// 	fMsgObs()
			// EndIf
			
			//Se deveria ser impresso as duplicatas
			If cImpDupl == "1"
				fImpDupl()
			EndIf
			
			//Imprime o rodape
			fImpRod()
			
			QRY_ORC->(DbSkip())
		EndDo
		
		//Gera o pdf para visualizacao
		oPrintPvt:Preview()
	
	Else
		MsgStop("Não há Pedidos!  ", "Atenção")
	EndIf
	QRY_ORC->(DbCloseArea())
Return



Static Function fImpCab()
	//Local cTexto      := ""
	Local nLinCab     := 025
	Local nLinCabOrig := nLinCab
	// Local cCodBar     := ""
	//Local nColMeiPed  := nColMeio+8+((nColMeio-nColIni)/2)
	Local lCNPJ       := (QRY_ORC->A1_PESSOA != "F")
	Local cCliAux     := QRY_ORC->CJ_CLIENTE+" "+QRY_ORC->CJ_LOJA+" - "+QRY_ORC->A1_NOME
	Local cCGC        := ""
	// Local cFretePed   := ""
	//Dados da empresa
	Local cEmpresa    := Iif(Empty(SM0->M0_NOMECOM), Alltrim(SM0->M0_NOME), Alltrim(SM0->M0_NOMECOM))
	Local cEmpTel     := Alltrim(Transform(SubStr(SM0->M0_TEL, 1, Len(SM0->M0_TEL)), cMaskTel))
	Local cEmpFax     := Alltrim(Transform(SubStr(SM0->M0_FAX, 1, Len(SM0->M0_FAX)), cMaskTel))
	Local cEmpCidade  := AllTrim(SM0->M0_CIDENT)+" / "+SM0->M0_ESTENT
	Local cEmpCnpj    := Alltrim(Transform(SM0->M0_CGC, cMaskCNPJ))
	Local cEmpCep     := Alltrim(Transform(SM0->M0_CEPENT, cMaskCEP))
	
	//Iniciando Página
	oPrintPvt:StartPage()
	
	//Dados da Empresa
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + 150, nColMeio-3)
	oPrintPvt:Line(nLinCab+nTamFundo, nColIni, nLinCab+nTamFundo, nColMeio-3)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni+5, "Emitente:",                                      oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayBitmap(nLinCab+3, nColIni+5, cLogoEmp, 054, 054)
	oPrintPvt:SayAlign(nLinCab,    nColIni+65, "Empresa:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColIni+110, cEmpresa,                                       oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "CNPJ:",                                          oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpCnpj,                                        oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Cidade:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpCidade,                                      oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "CEP:",                                           oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpCep,                                         oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Telefone:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpTel,                                         oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Telefone:",                                      oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpFax,                                         oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "e-Mail:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpEmail,                                       oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,   nColIni+65, "Site:",                                     		oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,   nColIni+110, cEmpSite,                                        oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	
	//Dados do Pedidox
	nLinCab := nLinCabOrig
	oPrintPvt:Box(nLinCab, nColMeio+3, nLinCab + 150, nColFin)
	oPrintPvt:Line(nLinCab+nTamFundo, nColMeio+3, nLinCab+nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColMeio+8,  "Pedido:",                                   	oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Num.Pedido:",                               	oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+58, QRY_ORC->CJ_NUM,                                oFontCab,  100, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Dt.Emissao:",                                  oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+58, dToC(QRY_ORC->CJ_EMISSAO),                      oFontCab,  100, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Cliente:",                                     oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+38, cCliAux,                                        oFontCab, 300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Nome Fantasia:",                               oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+68, QRY_ORC->A1_NREDUZ,  	                        oFontCab, 300, 07, , nPadLeft, )
	nLinCab += 10
	cCGC := QRY_ORC->A1_CGC
	If lCNPJ
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCNPJ)), "-")
		oPrintPvt:SayAlign(nLinCab, nColMeio+8, "CNPJ:",                                        oFontCabN, 060, 07, , nPadLeft, )
	Else
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCPF)), "-")
		oPrintPvt:SayAlign(nLinCab, nColMeio+8, "CPF:",                                         oFontCabN, 060, 07, , nPadLeft, )
	EndIf
	oPrintPvt:SayAlign(nLinCab, nColMeio+32, cCGC,                                              oFontCab,  300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Telefone:",	                                    oFontCabN, 035, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+045,"("+QRY_ORC->A1_DDD+")",							oFontCab,  039, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+065,QRY_ORC->A1_TEL,	 								oFontCab,  190, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "E-mail:",		                                    oFontCabN, 030, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+038, QRY_ORC->A1_EMAIL,		 						oFontCab,  300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Endereco:",	                                    oFontCabN, 040, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+048, QRY_ORC->A1_END,			 						oFontCab,  300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Bairro, Cidade - UF:",                             oFontCabN, 090, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+100, QRY_ORC->A1_BAIRRO, 								oFontCab,  130, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+200,","+QRY_ORC->A1_MUN,	 							oFontCab,  180, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+300," - "+QRY_ORC->A1_EST,								oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 10
	// If QRY_ORC->CJ_TPFRETE == "C"
	// 	cFretePed := "CIF"
	// ElseIf QRY_ORC->CJ_TPFRETE == "F"
	// 	cFretePed := "FOB"
	// ElseIf QRY_ORC->CJ_TPFRETE == "T"
	// 	cFretePed := "Terceiros"
	// Else
	// 	cFretePed := "Sem Frete"
	// EndIf
	// cFretePed += " - "+Alltrim(Transform(QRY_ORC->CJ_FRETE, cMaskFrete))
	// oPrintPvt:SayAlign(nLinCab, nColMeio+32, cFretePed,                                         oFontCab,  060, 07, , nPadLeft, )
	// nLinCab += 13
	// oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Natureza:",                                        oFontCabN, 060, 07, , nPadLeft, )
	// oPrintPvt:SayAlign(nLinCab, nColMeio+50, Upper(Posicione("SED",1,FwxFilial("SED")+QRY_ORC->CJ_NATUREZ,"ED_DESCRIC")), oFontCab,  200, 07, , nPadLeft, )

	//Código de barras
	nLinCab := nLinCabOrig
	// If cTipoBar $ "1;2"
	// 	If cTipoBar == "1"
	// 		cCodBar := QRY_ORC->CJ_NUM
	// 	ElseIf cTipoBar == "2"
	// 		cCodBar := QRY_ORC->CJ_FILIAL+QRY_ORC->CJ_NUM
	// 	EndIf
	// 	oPrintPvt:Code128C(nLinCab+90+nTamFundo, nColFin-60, cCodBar, 28)
	// 	oPrintPvt:SayAlign(nLinCab+92+nTamFundo, nColFin-60, cCodBar, oFontRod, 080, 07, , nPadLeft, )
	// EndIf

	//Ti­tulo
	nLinCab := nLinCabOrig + 155
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni, "Itens do Pedido de Venda:", oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
	//Linha Separatorio
	nLinCab += 5
	
	//Cabecalho com descricao das colunas
	nLinCab += 7

		oPrintPvt:SayAlign(nLinCab,   nPosCod,  "Cod.Prod.",        oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosDesc, "Descricao",        oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosUnid, "Uni.Med.",         oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosNCM , "NCM"      ,        oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosQuan, "Quant.",           oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosVUni, "Prc. Unit.",		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVUni, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab,   nPosVTot, "Vlr. Total", 		oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab+10, nPosVTot, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab,   nPosSTVl, "Prc. Unit.",       oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab+10, nPosSTVl, "+ Imposto",       oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab,   nPosSTTo, "Vl.Total",         oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab+10, nPosSTTo, "+ Imposto",       oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab,   nPosAIcm, "A.ICMS",           oFontDetN, 050, 07, , nPadLeft,)
		// oPrintPvt:SayAlign(nLinCab,   nPosEnt , "Dt. Entrega",      oFontDetN, 050, 07, , nPadLeft,)
	
	//Atualizando a linha inicial do relatório
	nLinAtu := nLinCab + 20
Return


/*---------------------------------------------------------------------*
 | Func:  fImpRod                                                      |
 | Desc:  Funcao que imprime o rodape                                  |
 *---------------------------------------------------------------------*/

Static Function fImpRod()
	Local nLinRod:= nLinFin + 10
	Local cTexto := ""
	
	//Linha SeparatÃ³ria
	oPrintPvt:Line(nLinRod, nColIni, nLinRod, nColFin)
	nLinRod += 3

	//Dados da Esquerda
	cTexto := "Pedido: "+QRY_ORC->CJ_NUM+"    |    "+dToC(dDataBase)+"     "+cHoraEx+"     "+FunName()+"     "+cUserName
	oPrintPvt:SayAlign(nLinRod, nColIni,    cTexto, oFontRod, 250, 07, , nPadLeft, )
	
	//Direita
	cTexto := "Página "+cValToChar(nPagAtu)
	oPrintPvt:SayAlign(nLinRod, nColFin-40, cTexto, oFontRod, 040, 07, , nPadRight, )
	
	//Finalizando a Página e somando mais um
	oPrintPvt:EndPage()
	nPagAtu++
Return

/*---------------------------------------------------------------------*
 | Func:  fLogoEmp                                                     |
 | Desc:  Funcao que retorna o logo da empresa (igual a DANFE)         |
 *---------------------------------------------------------------------*/

Static Function fLogoEmp()
	Local cGrpCompany := AllTrim(FWGrpCompany())
	Local cCodEmpGrp  := AllTrim(FWCodEmp())
	Local cUnitGrp    := AllTrim(FWUnitBusiness())
	Local cFilGrp     := AllTrim(FWFilial())
	Local cLogo       := ""
	Local cCamFim     := GetTempPath()
	Local cStart      := GetSrvProfString("Startpath", "")

	//Se tiver filiais por grupo de empresas
	If !Empty(cUnitGrp)
		cDescLogo	:= cGrpCompany + cCodEmpGrp + cUnitGrp + cFilGrp
		
	//Se nao, será apenas, empresa + filial
	Else
		cDescLogo	:= cEmpAnt + cFilAnt
	EndIf
	
	//Pega a imagem
	cLogo := cStart + "LGMID" + cDescLogo + ".PNG"
	
	//Se o arquivo Nao existir, pega apenas o da empresa, desconsiderando a filial
	If !File(cLogo)
		cLogo	:= cStart + "LGMID" + cEmpAnt + ".PNG"
	EndIf
	
	//Copia para a temporaria do s.o.
	CpyS2T(cLogo, cCamFim)
	cLogo := cCamFim + StrTran(cLogo, cStart, "")
	
	//Se o arquivo Nao existir na temporaria, espera meio segundo para terminar a cópia
	If !File(cLogo)
		Sleep(500)
	EndIf
Return cLogo

/*---------------------------------------------------------------------*
 | Func:  fMudaLayout                                                  |
 | Desc:  Funcao que muda as variaveis das colunas do layout           |
 *---------------------------------------------------------------------*/

Static Function fMudaLayout()
	oFontRod   := TFont():New(cNomeFont, , -06, , .F.)
	oFontTit   := TFont():New(cNomeFont, , -15, , .T.)
	oFontCab   := TFont():New(cNomeFont, , -10, , .F.)
	oFontCabN  := TFont():New(cNomeFont, , -10, , .T.)
	
	
		nPosCod  := 0010 //Código do Produto 
		nPosDesc := 0100 //Descricao
		nPosUnid := 0400 //Unidade de Medida
		nPosNCM  := 0435 //NCM
		nPosQuan := 0490 //Quantidade
		nPosVUni := 0530 //Valor Unitario
		nPosVTot := 0580 //Valor Total
		// nPosSTVl := 0630 //Valor Unitario + ST
		// nPosSTTo := 0680 //Valor Total ST
		// nPosAIcm := 0730 //Aliquota ICMS
		nPosEnt  := 0780 //Entrega
		
		oFontDet   := TFont():New(cNomeFont, , -10, , .F.)
		oFontDetN  := TFont():New(cNomeFont, , -10, , .T.)
		
Return

/*---------------------------------------------------------------------*
 | Func:  fImpTot                                                      |
 | Desc:  Funcao para imprimir os totais                               |
 *---------------------------------------------------------------------*/

Static Function fImpTot()
	nLinAtu += 7
	
	//Se atingir o fim da Página, quebra
	If nLinAtu + 50 >= nLinFin
		fImpRod()
		fImpCab()
	EndIf
	
	//Cria o grupo de Total
	oPrintPvt:Box(nLinAtu, nColIni, nLinAtu + 070, nColFin)
	oPrintPvt:Line(nLinAtu+nTamFundo, nColIni, nLinAtu+nTamFundo, nColFin)
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni+5, "Totais:",                                         oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 7
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor do Frete: ",                                oFontCab,  080, 07, , nPadLeft, )
	// oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotFrete, cMaskFrete)),         oFontCabN, 080, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+005, "Peso.Liq.:",                                      oFontCab,  080, 07, , nPadLeft, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total dos Descontos: ",                     oFontCab,  150, 07, , nPadLeft, )
	// oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nDesconto, cMaskVlr)),           oFontCabN, 080, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+005, "Peso.Bru:",                                       oFontCab,  080, 07, , nPadLeft, )

	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total dos Produtos: ",                      oFontCab,  150, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nValorTot, cMaskVlr)),           oFontCabN, 080, 07, , nPadRight, )


Return

/*---------------------------------------------------------------------*
 | Func:  fMsgObs                                                      |
 | Desc:  Funcao para imprimir mensagem de observação                  |
 *---------------------------------------------------------------------*/

Static Function fMsgObs()
	Local aMsg  := {"", "", ""}
	Local nQueb := 100
	Local cMsg  := ""
	nLinAtu += 4
	
	//Se atingir o fim da Página, quebra
	If nLinAtu + 40 >= nLinFin
		fImpRod()
		fImpCab()
	EndIf
	
	//Quebrando a mensagem
	If Len(cMsg) > nQueb
		aMsg[1] := SubStr(cMsg,    1, nQueb)
		aMsg[1] := SubStr(aMsg[1], 1, RAt(' ', aMsg[1]))
		
		//Pegando o restante e adicionando nas outras linhas
		cMsg := Alltrim(SubStr(cMsg, Len(aMsg[1])+1, Len(cMsg)))
		If Len(cMsg) > nQueb
			aMsg[2] := SubStr(cMsg,    1, nQueb)
			aMsg[2] := SubStr(aMsg[2], 1, RAt(' ', aMsg[2]))
			
			cMsg := Alltrim(SubStr(cMsg, Len(aMsg[2])+1, Len(cMsg)))
			aMsg[3] := cMsg
		Else
			aMsg[2] := cMsg
		EndIf
	Else
		aMsg[1] := cMsg
	EndIf
	
	//Cria o grupo de observação
	oPrintPvt:Box(nLinAtu, nColIni, nLinAtu + 038, nColFin)
	oPrintPvt:Line(nLinAtu+nTamFundo, nColIni, nLinAtu+nTamFundo, nColFin)
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni+5, "Observacao:",                oFontTit,  100, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 5
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, aMsg[1],                      oFontCab,  400, 07, , nPadLeft, )
	nLinAtu += 7
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, aMsg[2],                      oFontCab,  400, 07, , nPadLeft, )
	nLinAtu += 7
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, aMsg[3],                      oFontCab,  400, 07, , nPadLeft, )
	nLinAtu += 10
Return

/*---------------------------------------------------------------------*
 | Func:  fMontDupl                                                    |
 | Desc:  FunÃ§Ã£o que monta o array de duplicatas                       |
 *---------------------------------------------------------------------*/

// Static Function fMontDupl()
// 	Local aArea    := GetArea()
// 	Local lDtEmi   := SuperGetMv("MV_DPDTEMI", .F., .T.)
// 	Local nAcerto  := 0
// 	Local aEntr    := {}
// 	Local aDupl    := {}
// 	Local aDuplTmp := {}
// 	Local nItem    := 0
// 	Local nAux     := 0
	
// 	aDuplicatas := {}
	
// 	//Posiciona na condiÃ§Ã£o de pagamento
// 	DbSelectarea("SE4")
// 	SE4->(DbSetOrder(1))
// 	SE4->(DbSeek(xFilial("SE4")+SCJ->CJ_CONDPAG))
	
// 	//Se na planilha financeira do Pedido de Venda as duplicatas serÃ£o separadas pela Emissao
// 	If lDtEmi
// 		//Se Nao for do tipo 9
// 		If (SE4->E4_TIPO != "9")
// 			//Pega as datas e valores das duplicatas
// 			// aDupl := Condicao(MaFisRet(, "NF_BASEDUP"), SCJ->CJ_CONDPAG, MaFisRet(, "NF_VALIPI"), SCJ->CJ_EMISSAO, MaFisRet(, "NF_VALSOL"))
			
// 			//Se tiver dados, percorre os valores e adiciona dados na Ãºltima parcela
// 			If Len(aDupl) > 0
// 				For nAux := 1 To Len(aDupl)
// 					nAcerto += aDupl[nAux][2]
// 				Next nAux
// 				aDupl[Len(aDupl)][2] += MaFisRet(, "NF_BASEDUP") - nAcerto
// 			EndIf
		
// 		//Adiciona uma Ãºnica linha
// 		Else
// 			aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
// 		EndIf
		
// 	Else
// 		//Percorre os itens
// 		nItem := 0
// 		QRY_ITE->(DbGoTop())
// 		While ! QRY_ITE->(EoF())
// 			nItem++
			
// 			//Se tiver entrega
// 			If !Empty(QRY_ITE->CK_ENTREG)
				
// 				//Procura pela data de entrega no Array
// 				nPosEntr := Ascan(aEntr, {|x| x[1] == QRY_ITE->CK_ENTREG})
				
// 				//Se Nao encontrar cria a Linha, do contrÃ¡rio atualiza os valores
//  				If nPosEntr == 0
// 					aAdd(aEntr, {QRY_ITE->CK_ENTREG, MaFisRet(nItem, "IT_BASEDUP"), MaFisRet(nItem, "IT_VALIPI"), MaFisRet(nItem, "IT_VALSOL")})
// 				Else
// 					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_BASEDUP")
// 					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_VALIPI")
// 					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_VALSOL")
// 				EndIf
// 			EndIf
			
// 			QRY_ITE->(DbSkip())
// 		EndDo
		
// 		//Se Nao for CondiÃ§Ã£o do tipo 9
// 		If (SE4->E4_TIPO != "9")
			
// 			//Percorre os valores conforme data de entrega
// 			For nItem := 1 to Len(aEntr)
// 				nAcerto  := 0
// 				aDuplTmp := Condicao(aEntr[nItem][2], SCJ->CJ_CONDPAG, aEntr[nItem][3], aEntr[nItem][1], aEntr[nItem][4])
				
// 				//Atualiza o valor da Ãºltima parcela
// 				For nAux := 1 To Len(aDuplTmp)
// 					nAcerto += aDuplTmp[nAux][2]
// 				Next nAux
// 				aDuplTmp[Len(aDuplTmp)][2] += aEntr[nItem][2] - nAcerto
				
// 				//Percorre o temporÃ¡rio e adiciona no duplicatas
// 				aEval(aDuplTmp, {|x| aAdd(aDupl, {aEntr[nItem][1], x[1], x[2]})})
// 			Next
			
// 		Else
// 	    	aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
// 		EndIf
// 	EndIf
	
// 	//Se Nao tiver duplicatas, adiciona em branco
// 	If Len(aDupl) == 0
// 		aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
// 	EndIf
	
// 	aDuplicatas := aClone(aDupl)
// 	RestArea(aArea)
// Return

/*---------------------------------------------------------------------*
 | Func:  fImpDupl                                                     |
 | Desc:  FunÃ§Ã£o para imprimir as duplicatas                           |
 *---------------------------------------------------------------------*/

Static Function fImpDupl()
	Local nLinhas 		:= NoRound(Len(aDuplicatas)/2, 0) + 1
	Local nAtual  		:= 0
	Local nLinDup 		:= 0
	Local nLinLim 		:= nLinAtu + ((nLinhas+1)*7) + nTamFundo
	Local nColAux 		:= nColIni
	nLinAtu += 7
	
	//Se atingir o fim da Página, quebra
	If nLinLim+5 >= nLinFin
		fImpRod()
		fImpCab()
	EndIf
	
	// Condicao de Pagamento
	oPrintPvt:Box(nLinAtu, nColIni, nLinAtu + nTamFundo, nColFin)
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni, "Condicao de Pagamento:  " +QRY_ORC->E4_DESCRI, 									oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
	nLinAtu += 5

	//Cria o grupo de Duplicatas
	nLinAtu += nTamFundo - 5
	oPrintPvt:SayAlign(nLinAtu-10, nColIni+5,  "Duplicatas",                													oFontTit,  100, nTamFundo, nCorAzul, nPadLeft, )
	nLinAtu += 5
	nLinDup := nLinAtu

	//Percorre as duplicatas
	For nAtual := 1 To Len(aDuplicatas)
		oPrintPvt:SayAlign(nLinDup, nColAux+0005, StrZero(nAtual, 3)+", no dia "+dToC(aDuplicatas[nAtual][1])+":", 				oFontCab,  150, 07, , nPadLeft, )
		oPrintPvt:SayAlign(nLinDup, nColAux+0095, Alltrim(Transform(aDuplicatas[nAtual][2], cMaskVlr)),            				oFontCabN, 080, 07, , nPadRight, )
		nLinDup += 7
		
		//Se atingiu o Número de linhas, muda para imprimir na coluna do meio
		If nAtual == nLinhas
			nLinDup := nLinAtu
			nColAux := nColMeio
		EndIf
	Next

	nLinAtu += (nLinhas*7) + 3
	nLinAtu += 3
	oPrintPvt:Line(nLinDup+nTamFundo, nColIni+3, nLinDup+nTamFundo, nColFin)
Return
