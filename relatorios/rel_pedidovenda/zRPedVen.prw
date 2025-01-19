//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

//Variaveis utilizadas no fonte inteiro
Static nPadLeft   := 0                                                                     //Alinhamento a Esquerda
Static nPadRight  := 1                                                                     //Alinhamento a Direita
Static nPadCenter := 2                                                                     //Alinhamento Centralizado
Static nPosCod    := 0000                                                                  //Posição Inicial da Coluna de Cídigo do Produto 
Static nPosDesc   := 0000                                                                  //Posição Inicial da Coluna de Descrição
Static nPosNCM    := 0000                                                                  //Posição Inicial da Coluna de NCM
Static nPosUnid   := 0000                                                                  //Posição Inicial da Coluna de Unidade de Medida
Static nPosQuan   := 0000                                                                  //Posição Inicial da Coluna de Quantidade
Static nPosVUni   := 0000                                                                  //Posição Inicial da Coluna de Valor Unitario
Static nPosVTot   := 0000                                                                  //Posição Inicial da Coluna de Valor Total

Static nPosBIcm   := 0000                                                                  //Posição Inicial da Coluna de Base Calculo ICMS
Static nPosVIcm   := 0000                                                                  //Posição Inicial da Coluna de Valor ICMS
Static nPosVIPI   := 0000                                                                  //Posição Inicial da Coluna de Valor Ipi
Static nPosAIcm   := 0000                                                                  //Posição Inicial da Coluna de Aliquota ICMS
Static nPosAIpi   := 0000                                                                  //Posição Inicial da Coluna de Aliquota IPI
Static nPosSTUn   := 0000                                                                  //Posição Inicial da Coluna de Valor Unitírio ST
Static nPosSTVl   := 0000                                                                  //Posição Inicial da Coluna de Valor Unitírio + ST
Static nPosSTBa   := 0000                                                                  //Posição Inicial da Coluna de Base do ST
Static nPosSTTo   := 0000                                                                  //Posição Inicial da Coluna de Valor Total ST
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
Static cMaskCNPJ  := "@R 99.999.999/9999-99"                                               //Míscara de CNPJ
Static cMaskCEP   := "@R 99999-999"                                                        //Míscara de CEP
Static cMaskCPF   := "@R 999.999.999-99"                                                   //Míscara de CPF
Static cMaskQtd   := PesqPict("SC6", "C6_QTDVEN")                                          //Míscara de quantidade
Static cMaskPrc   := PesqPict("SC6", "C6_VALOR")                                          //Míscara de preío
Static cMaskVlr   := PesqPict("SC6", "C6_VALOR")                                           //Míscara de valor
Static cMaskFrete := PesqPict("SC5", "C5_FRETE")                                           //Míscara de frete
Static cMaskPBru  := PesqPict("SC5", "C5_PBRUTO")                                          //Míscara de peso bruto
Static cMaskPLiq  := PesqPict("SC5", "C5_PESOL")                                           //Míscara de peso liquido

/*/{Protheus.doc} zRPedVen
Impressão Grafica generica de Pedido de Venda (em pdf)
@type function
@author Atilio
@since 19/06/2016
@version 1.0
	@example
	u_zRPedVen()
/*/

User Function zRPedVen()
	Local aArea      := GetArea()
	Local aAreaC5    := SC5->(GetArea())
	Local aPergs     := {}
	Local aRetorn    := {}
	Local oProcess   := Nil
	//Variaveis usadas nas outras funçães
	Private cLogoEmp := fLogoEmp()
	Private cPedDe   := SC5->C5_NUM
	Private cPedAt   := SC5->C5_NUM
	Private cLayout  := "1"
	Private cTipoBar := "3"
	Private cImpDupl := "1"
	Private cZeraPag := "1"
	
	//Adiciona os parâmetro para a pergunta
	aAdd(aPergs, {1, "Pedido De",  cPedDe, "", ".T.", "SC5", ".T.", 80, .T.})
	aAdd(aPergs, {1, "Pedido Ate", cPedAt, "", ".T.", "SC5", ".T.", 80, .T.})
	aAdd(aPergs, {2, "Layout",                         Val(cLayout),  {"1=Dados com ST",     "2=Dados com IPI"},                                       100, ".T.", .F.})
	aAdd(aPergs, {2, "Código de Barras",               Val(cTipoBar), {"1=Número do Pedido", "2=Filial + Número do Pedido", "3=Sem Código de Barras"}, 100, ".T.", .F.})
	aAdd(aPergs, {2, "Imprimir Previsão Duplicatas",   Val(cImpDupl), {"1=Sim",              "2=Nao"},                                                 100, ".T.", .F.})
	aAdd(aPergs, {2, "Zera a Página ao trocar Pedido", Val(cZeraPag), {"1=Sim",              "2=Nao"},                                                 100, ".T.", .F.})
	
	//Se a pergunta for confirmada
	If ParamBox(aPergs, "Informe os parâmetro", @aRetorn, , , , , , , , .F., .F.)
		cPedDe   := aRetorn[1]
		cPedAt   := aRetorn[2]
		cLayout  := cValToChar(aRetorn[3])
		cTipoBar := cValToChar(aRetorn[4])
		cImpDupl := cValToChar(aRetorn[5])
		cZeraPag := cValToChar(aRetorn[6])
		
		//Funcao que muda alinhamento e fontes
		fMudaLayout()
		
		//Chama o processamento do relatório
		oProcess := MsNewProcess():New({|| fMontaRel(@oProcess) }, "Impressão Pedidos de Venda", "Processando", .F.)
		oProcess:Activate()
	EndIf
	
	RestArea(aAreaC5)
	RestArea(aArea)
Return

/*---------------------------------------------------------------------*
 | Func:  fMontaRel                                                    |
 | Desc:  FunÃ§Ã£o principal que monta o relatório                       |
 *---------------------------------------------------------------------*/

Static Function fMontaRel(oProc)
	//Variaveis usada no controle das ríguas
	Local nTotIte       := 0
	Local nItAtu        := 0
	Local nTotPed       := 0
	Local nPedAtu       := 0
	//Consultas SQL
	Local cQryPed       := ""
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
	DbSelectArea("SC5")
	
	//Criando o objeto de Impressao
	oPrintPvt := FWMSPrinter():New(cNomeRel, IMP_PDF, .F., /*cStartPath*/, .T., , @oPrintPvt, , , , , .T.)
	oPrintPvt:cPathPDF := GetTempPath()
	oPrintPvt:SetResolution(72)
	oPrintPvt:SetLandscape()
	oPrintPvt:SetPaperSize(DMPAPER_A4)
	oPrintPvt:SetMargin(10, 10, 10, 10)
	
	//Selecionando os Pedidos
	cQryPed := " SELECT "                                        + CRLF
	cQryPed += "    C5_FILIAL, "                                 + CRLF
	cQryPed += "    C5_NUM, "                                    + CRLF
	cQryPed += "    C5_EMISSAO, "                                + CRLF
	cQryPed += "    C5_CLIENTE, "                                + CRLF
	cQryPed += "    C5_LOJACLI, "                                + CRLF
	cQryPed += "    ISNULL(A1_NOME, '') AS A1_NOME, "       	 + CRLF
	cQryPed += "    ISNULL(A1_NREDUZ, '') AS A1_NREDUZ, "      	 + CRLF
	cQryPed += "    ISNULL(A1_PESSOA, '') AS A1_PESSOA, "        + CRLF
	cQryPed += "    ISNULL(A1_CGC, '') AS A1_CGC, "              + CRLF
	cQryPed += "    ISNULL(A1_END, '') AS A1_END, "              + CRLF
	cQryPed += "    ISNULL(A1_BAIRRO, '') AS A1_BAIRRO, "        + CRLF
	cQryPed += "    ISNULL(A1_MUN, '') AS A1_MUN, "              + CRLF
	cQryPed += "    ISNULL(A1_EST, '') AS A1_EST, "              + CRLF
	cQryPed += "    ISNULL(A1_DDD, '') AS A1_DDD, "       		 + CRLF
	cQryPed += "    ISNULL(A1_TEL, '') AS A1_TEL, "       		 + CRLF
	cQryPed += "    ISNULL(A1_EMAIL, '') AS A1_EMAIL, "       	 + CRLF
	cQryPed += "    C5_CONDPAG, "                                + CRLF
	cQryPed += "    ISNULL(E4_DESCRI, '') AS E4_DESCRI, "        + CRLF
	cQryPed += "    C5_TRANSP, "                                 + CRLF
	cQryPed += "    ISNULL(A4_NREDUZ, '') AS A4_NREDUZ, "        + CRLF
	cQryPed += "    C5_VEND1, "                                  + CRLF
	cQryPed += "    ISNULL(A3_NREDUZ, '') AS A3_NREDUZ, "        + CRLF
	cQryPed += "    C5_TPFRETE, "                                + CRLF
	cQryPed += "    C5_FRETE, "                                  + CRLF
	cQryPed += "    C5_PESOL, "                                  + CRLF
	cQryPed += "    C5_PBRUTO, "                                 + CRLF
	cQryPed += "    C5_MENNOTA, "                                + CRLF
	cQryPed += "    C5_NATUREZ, "                                + CRLF
	cQryPed += "    SC5.R_E_C_N_O_ AS C5REC "                    + CRLF
	cQryPed += " FROM "                                          + CRLF
	cQryPed += "    "+RetSQLName("SC5")+" SC5 "                  + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SA1")+" SA1 ON ( "   + CRLF
	cQryPed += "        A1_FILIAL   = '"+FWxFilial("SA1")+"' "   + CRLF
	cQryPed += "        AND A1_COD  = SC5.C5_CLIENTE "           + CRLF
	cQryPed += "        AND A1_LOJA = SC5.C5_LOJACLI "           + CRLF
	cQryPed += "        AND SA1.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SE4")+" SE4 ON ( "   + CRLF
	cQryPed += "        E4_FILIAL     = '"+FWxFilial("SE4")+"' " + CRLF
	cQryPed += "        AND E4_CODIGO = SC5.C5_CONDPAG "         + CRLF
	cQryPed += "        AND SE4.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SA4")+" SA4 ON ( "   + CRLF
	cQryPed += "        A4_FILIAL  = '"+FWxFilial("SA4")+"' "    + CRLF
	cQryPed += "        AND A4_COD = SC5.C5_TRANSP "             + CRLF
	cQryPed += "        AND SA4.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += "    LEFT JOIN "+RetSQLName("SA3")+" SA3 ON ( "   + CRLF
	cQryPed += "        A3_FILIAL  = '"+FWxFilial("SA3")+"' "    + CRLF
	cQryPed += "        AND A3_COD = SC5.C5_VEND1 "              + CRLF
	cQryPed += "        AND SA3.D_E_L_E_T_ = ' ' "               + CRLF
	cQryPed += "    ) "                                          + CRLF
	cQryPed += " WHERE "                                         + CRLF
	cQryPed += "    C5_FILIAL   = '"+FWxFilial("SC5")+"' "       + CRLF
	cQryPed += "    AND C5_NUM >= '"+cPedDe+"' "                 + CRLF
	cQryPed += "    AND C5_NUM <= '"+cPedAt+"' "                 + CRLF
	cQryPed += "    AND SC5.D_E_L_E_T_ = ' ' "                   + CRLF
	TCQuery cQryPed New Alias "QRY_PED"
	TCSetField("QRY_PED", "C5_EMISSAO", "D")
	Count To nTotPed
	oProc:SetRegua1(nTotPed)
	
	//Somente se houver Pedidos
	If nTotPed != 0
	
		//Enquanto houver Pedidos
		QRY_PED->(DbGoTop())
		While ! QRY_PED->(EoF())
			If cZeraPag == "1"
				nPagAtu := 1
			EndIf
			nPedAtu++
			oProc:IncRegua1("Processando o Pedido "+cValToChar(nPedAtu)+" de "+cValToChar(nTotPed)+"...")
			oProc:SetRegua2(1)
			oProc:IncRegua2("...")
			
			//Imprime o cabecalho
			fImpCab()
			
			//Inicializa os calculos de impostos
			nItAtu    := 0
			nTotIte   := 0
			nTotalST  := 0
			nTotIPI   := 0
			nDesconto := 0
			SC5->(DbGoTo(QRY_PED->C5REC))
			MaFisIni(SC5->C5_CLIENTE,;                   // 01 - Código Cliente/Fornecedor
				SC5->C5_LOJACLI,;                        // 02 - Loja do Cliente/Fornecedor
				Iif(SC5->C5_TIPO $ "D;B", "F", "C"),;    // 03 - C:Cliente , F:Fornecedor
				SC5->C5_TIPO,;                           // 04 - Tipo da NF
				SC5->C5_TIPOCLI,;                        // 05 - Tipo do Cliente/Fornecedor
				MaFisRelImp("MT100", {"SF2", "SD2"}),;   // 06 - Relacao de Impostos que suportados no arquivo
				,;                                       // 07 - Tipo de complemento
				,;                                       // 08 - Permite Incluir Impostos no Rodape .T./.F.
				"SB1",;                                  // 09 - Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
				"MATA461")                               // 10 - Nome da rotina que esta utilizando a funcao
			
			//Seleciona agora os itens do Pedido
			cQryIte := " SELECT "                                      + CRLF
			cQryIte += "    C6_PRODUTO, "                              + CRLF
			cQryIte += "    ISNULL(B1_DESC, '') AS B1_DESC, "          + CRLF
			cQryIte += "    ISNULL(B1_POSIPI, '') AS B1_POSIPI, "      + CRLF
			cQryIte += "    C6_UM, "                                   + CRLF
			cQryIte += "    C6_ENTREG, "                               + CRLF
			cQryIte += "    C6_TES, "                                  + CRLF
			cQryIte += "    C6_QTDVEN, "                               + CRLF
			cQryIte += "    C6_PRCVEN, "                               + CRLF
			cQryIte += "    C6_VALDESC, "                              + CRLF
			cQryIte += "    C6_NFORI, "                                + CRLF
			cQryIte += "    C6_SERIORI, "                              + CRLF
			cQryIte += "    C6_VALOR "                                 + CRLF
			cQryIte += " FROM "                                        + CRLF
			cQryIte += "    "+RetSQLName("SC6")+" SC6 "                + CRLF
			cQryIte += "    LEFT JOIN "+RetSQLName("SB1")+" SB1 ON ( " + CRLF
			cQryIte += "        B1_FILIAL = '"+FWxFilial("SB1")+"' "   + CRLF
			cQryIte += "        AND B1_COD = SC6.C6_PRODUTO "          + CRLF
			cQryIte += "        AND SB1.D_E_L_E_T_ = ' ' "             + CRLF
			cQryIte += "    ) "                                        + CRLF
			cQryIte += " WHERE "                                       + CRLF
			cQryIte += "    C6_FILIAL = '"+FWxFilial("SC6")+"' "       + CRLF
			cQryIte += "    AND C6_NUM = '"+QRY_PED->C5_NUM+"' "       + CRLF
			cQryIte += "    AND SC6.D_E_L_E_T_ = ' ' "                 + CRLF
			cQryIte += " ORDER BY "                                    + CRLF
			cQryIte += "    C6_ITEM "                                  + CRLF
			TCQuery cQryIte New Alias "QRY_ITE"
			TCSetField("QRY_ITE", "C6_ENTREG", "D")
			Count To nTotIte
			nValorTot := 0
			oProc:SetRegua2(nTotIte)
			
			//Enquanto houver itens
			QRY_ITE->(DbGoTop())
			While ! QRY_ITE->(EoF())
				nItAtu++
				oProc:IncRegua2("Calculando impostos - item "+cValToChar(nItAtu)+" de "+cValToChar(nTotIte)+"...")
				
				//Pega os tratamentos de impostos
				SB1->(DbSeek(FWxFilial("SB1")+QRY_ITE->C6_PRODUTO))
				MaFisAdd(QRY_ITE->C6_PRODUTO,;    // 01 - Código do Produto                    ( Obrigatorio )
					QRY_ITE->C6_TES,;             // 02 - Código do TES                        ( Opcional )
					QRY_ITE->C6_QTDVEN,;          // 03 - Quantidade                           ( Obrigatorio )
					QRY_ITE->C6_PRCVEN,;          // 04 - Preco Unitario                       ( Obrigatorio )
					0,;         				  // 05 - Desconto
					QRY_ITE->C6_NFORI,;           // 06 - Número da NF Original                ( Devolucao/Benef )
					QRY_ITE->C6_SERIORI,;         // 07 - Serie da NF Original                 ( Devolucao/Benef )
					0,;                           // 08 - RecNo da NF Original no arq SD1/SD2
					0,;                           // 09 - Valor do Frete do Item               ( Opcional )
					0,;                           // 10 - Valor da Despesa do item             ( Opcional )
					0,;                           // 11 - Valor do Seguro do item              ( Opcional )
					0,;                           // 12 - Valor do Frete Autonomo              ( Opcional )
					QRY_ITE->C6_VALOR,;           // 13 - Valor da Mercadoria                  ( Obrigatorio )
					0,;                           // 14 - Valor da Embalagem                   ( Opcional )
					SB1->(RecNo()),;              // 15 - RecNo do SB1
					0)                            // 16 - RecNo do SF4
				
				nQtdPeso := QRY_ITE->C6_QTDVEN*SB1->B1_PESO
				MaFisLoad("IT_VALMERC", QRY_ITE->C6_VALOR, nItAtu)				
				MaFisAlt("IT_PESO", nQtdPeso, nItAtu)
				
				QRY_ITE->(DbSkip())
			EndDo
			
			//Altera dados da Nota
			MaFisAlt("NF_FRETE", SC5->C5_FRETE)
			MaFisAlt("NF_SEGURO", SC5->C5_SEGURO)
			//MaFisAlt("NF_DESPESA", SC5->C5_DESPESA) 
			MaFisAlt("NF_AUTONOMO", SC5->C5_FRETAUT)
			If SC5->C5_DESCONT > 0
				MaFisAlt("NF_DESCONTO", Min(MaFisRet(, "NF_VALMERC")-0.01, SC5->C5_DESCONT+MaFisRet(, "NF_DESCONTO")) )
			EndIf
			If SC5->C5_PDESCAB > 0
				MaFisAlt("NF_DESCONTO", A410Arred(MaFisRet(, "NF_VALMERC")*SC5->C5_PDESCAB/100, "C6_VALOR") + MaFisRet(, "NF_DESCONTO"))
			EndIf
			
			//Enquanto houver itens
			oProc:IncRegua2("...")
			oProc:SetRegua2(nTotIte)
			nItAtu := 0
			QRY_ITE->(DbGoTop())
			While ! QRY_ITE->(EoF())
				nItAtu++
				oProc:IncRegua2("Imprimindo item "+cValToChar(nItAtu)+" de "+cValToChar(nTotIte)+"...")
				
				//Pega os tratamentos de impostos
				SB1->(DbSeek(FWxFilial("SB1")+QRY_ITE->C6_PRODUTO))
				
				//Pega os valores
				nBasICM    := MaFisRet(nItAtu, "IT_BASEICM")
				nValICM    := MaFisRet(nItAtu, "IT_VALICM")
				nValIPI    := MaFisRet(nItAtu, "IT_VALIPI")
				nAlqICM    := MaFisRet(nItAtu, "IT_ALIQICM")
				nAlqIPI    := MaFisRet(nItAtu, "IT_ALIQIPI")
				nValSol    := (MaFisRet(nItAtu,"IT_VALSOL") / QRY_ITE->C6_QTDVEN) 
				nBasSol    := MaFisRet(nItAtu, "IT_BASESOL")
				nPrcUniSol := QRY_ITE->C6_PRCVEN + nValSol
				nTotSol    := nPrcUniSol * QRY_ITE->C6_QTDVEN
				nTotalST   += MaFisRet(nItAtu, "IT_VALSOL")
				nTotIPI    += nValIPI
				nDesconto  += QRY_ITE->C6_VALDESC
				
				//Imprime os dados
				If cLayout == "1"
					oPrintPvt:SayAlign(nLinAtu, nPosCod, QRY_ITE->C6_PRODUTO,                                oFontDet, 200, 35, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosDesc, QRY_ITE->B1_DESC,                                  oFontDet, 200, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosUnid, QRY_ITE->C6_UM,                                    oFontDet, 030, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosNCM , QRY_ITE->B1_POSIPI,                                oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosQuan, Alltrim(Transform(QRY_ITE->C6_QTDVEN, cMaskQtd)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVUni, Alltrim(Transform(QRY_ITE->C6_PRCVEN, cMaskPrc)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVTot, Alltrim(Transform(QRY_ITE->C6_VALOR, cMaskVlr)),   oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosSTVl, Alltrim(Transform(nPrcUniSol, cMaskPrc)),          oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosSTTo, Alltrim(Transform(nTotSol, cMaskVlr)),             oFontDet, 050, 07, , nPadLeft,) 
					oPrintPvt:SayAlign(nLinAtu, nPosAIcm, Alltrim(Transform(nAlqICM, cMaskPad)),             oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosEnt , DToC(QRY_ITE->C6_ENTREG),                          oFontDet, 050, 07, , nPadLeft,)
				Else
					oPrintPvt:SayAlign(nLinAtu, nPosCod, QRY_ITE->C6_PRODUTO,                                oFontDet, 200, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosDesc, QRY_ITE->B1_DESC,                                  oFontDet, 200, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosUnid, QRY_ITE->C6_UM,                                    oFontDet, 030, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosNCM , QRY_ITE->B1_POSIPI,                                oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosQuan, Alltrim(Transform(QRY_ITE->C6_QTDVEN, cMaskQtd)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVUni, Alltrim(Transform(QRY_ITE->C6_PRCVEN, cMaskPrc)),  oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosVTot, Alltrim(Transform(QRY_ITE->C6_VALOR, cMaskVlr)),   oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosAIcm, Alltrim(Transform(nAlqICM, cMaskPad)),             oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosAIpi, Alltrim(Transform(nAlqIPI, cMaskPad)),             oFontDet, 050, 07, , nPadLeft,)
					oPrintPvt:SayAlign(nLinAtu, nPosEnt , DToC(QRY_ITE->C6_ENTREG),                          oFontDet, 050, 07, , nPadLeft,)
				EndIf

				nLinAtu += 10
				
				//Se por acaso atingiu o limite da pagina, finaliza, e começa uma nova pagina
				If nLinAtu >= nLinFin
					fImpRod()
					fImpCab()
				EndIf
				
				nValorTot += QRY_ITE->C6_VALOR
				QRY_ITE->(DbSkip())
			EndDo
			nTotFrete := MaFisRet(, "NF_FRETE")
			nTotVal := MaFisRet(, "NF_TOTAL")
			fMontDupl()
			QRY_ITE->(DbCloseArea())
			MaFisEnd()
			
			//Imprime o Total do Pedido
			fImpTot()
			
			//Se tiver mensagem da observacao
			If !Empty(QRY_PED->C5_MENNOTA)
				fMsgObs()
			EndIf
			
			//Se deveria ser impresso as duplicatas
			If cImpDupl == "1"
				fImpDupl()
			EndIf
			
			//Imprime o rodape
			fImpRod()
			
			QRY_PED->(DbSkip())
		EndDo
		
		//Gera o pdf para visualizacao
		oPrintPvt:Preview()
	
	Else
		MsgStop("Não há Pedidos!", "Atenção")
	EndIf
	QRY_PED->(DbCloseArea())
Return

/*---------------------------------------------------------------------*
 | Func:  fImpCab                                                      |
 | Desc:  Funcao que imprime o cabecalho                               |
 *---------------------------------------------------------------------*/

Static Function fImpCab()
	//Local cTexto      := ""
	Local nLinCab     := 025
	Local nLinCabOrig := nLinCab
	Local cCodBar     := ""
	//Local nColMeiPed  := nColMeio+8+((nColMeio-nColIni)/2)
	Local lCNPJ       := (QRY_PED->A1_PESSOA != "F")
	Local cCliAux     := QRY_PED->C5_CLIENTE+" "+QRY_PED->C5_LOJACLI+" - "+QRY_PED->A1_NOME
	Local cCGC        := ""
	Local cFretePed   := ""
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
	oPrintPvt:SayAlign(nLinCab,    nColMeio+58, QRY_PED->C5_NUM,                                oFontCab,  100, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Dt.Emissao:",                                  oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+58, dToC(QRY_PED->C5_EMISSAO),                      oFontCab,  100, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Cliente:",                                     oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+38, cCliAux,                                        oFontCab, 300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab,    nColMeio+8,  "Nome Fantasia:",                               oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab,    nColMeio+68, QRY_PED->A1_NREDUZ,  	                        oFontCab, 300, 07, , nPadLeft, )
	nLinCab += 10
	cCGC := QRY_PED->A1_CGC
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
	oPrintPvt:SayAlign(nLinCab, nColMeio+045,"("+QRY_PED->A1_DDD+")",							oFontCab,  039, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+065,QRY_PED->A1_TEL,	 								oFontCab,  190, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "E-mail:",		                                    oFontCabN, 030, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+038, QRY_PED->A1_EMAIL,		 						oFontCab,  300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Endereco:",	                                    oFontCabN, 040, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+048, QRY_PED->A1_END,			 						oFontCab,  300, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Bairro, Cidade - UF:",                             oFontCabN, 090, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+100, QRY_PED->A1_BAIRRO, 								oFontCab,  130, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+200,","+QRY_PED->A1_MUN,	 							oFontCab,  180, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+300," - "+QRY_PED->A1_EST,								oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Vendedor:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+50, QRY_PED->C5_VEND1 + " - "+QRY_PED->A3_NREDUZ,      oFontCab,  120, 07, , nPadLeft, )
	nLinCab += 10
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Frete:",                                           oFontCabN, 060, 07, , nPadLeft, )
	If QRY_PED->C5_TPFRETE == "C"
		cFretePed := "CIF"
	ElseIf QRY_PED->C5_TPFRETE == "F"
		cFretePed := "FOB"
	ElseIf QRY_PED->C5_TPFRETE == "T"
		cFretePed := "Terceiros"
	Else
		cFretePed := "Sem Frete"
	EndIf
	cFretePed += " - "+Alltrim(Transform(QRY_PED->C5_FRETE, cMaskFrete))
	oPrintPvt:SayAlign(nLinCab, nColMeio+32, cFretePed,                                         oFontCab,  060, 07, , nPadLeft, )
	nLinCab += 13
	oPrintPvt:SayAlign(nLinCab, nColMeio+8, "Natureza:",                                        oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio+50, Upper(Posicione("SED",1,FwxFilial("SED")+QRY_PED->C5_NATUREZ,"ED_DESCRIC")), oFontCab,  200, 07, , nPadLeft, )
	//Código de barras
	nLinCab := nLinCabOrig
	If cTipoBar $ "1;2"
		If cTipoBar == "1"
			cCodBar := QRY_PED->C5_NUM
		ElseIf cTipoBar == "2"
			cCodBar := QRY_PED->C5_FILIAL+QRY_PED->C5_NUM
		EndIf
		oPrintPvt:Code128C(nLinCab+90+nTamFundo, nColFin-60, cCodBar, 28)
		oPrintPvt:SayAlign(nLinCab+92+nTamFundo, nColFin-60, cCodBar, oFontRod, 080, 07, , nPadLeft, )
	EndIf

	//Ti­tulo
	nLinCab := nLinCabOrig + 155
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni, "Itens do Pedido de Venda:", oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
	//Linha Separatorio
	nLinCab += 5
	
	//Cabecalho com descricao das colunas
	nLinCab += 7
	If cLayout == "1"
		oPrintPvt:SayAlign(nLinCab,   nPosCod,  "Cod.Prod.",        oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosDesc, "Descricao",        oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosUnid, "Uni.Med.",         oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosNCM , "NCM"      ,        oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosQuan, "Quant.",           oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosVUni, "Prc. Unit.",		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVUni, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosVTot, "Vlr. Total", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVTot, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosSTVl, "Prc. Unit.",       oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosSTVl, "+ Imposto",       oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosSTTo, "Vl.Total",         oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosSTTo, "+ Imposto",       oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosAIcm, "A.ICMS",           oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,   nPosEnt , "Dt. Entrega",      oFontDetN, 050, 07, , nPadLeft,)
	 Else
		oPrintPvt:SayAlign(nLinCab, nPosCod,  "Cod.Prod.",          oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosDesc, "Descricao",          oFontDetN, 100, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosUnid, "Uni.Med.",           oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosNCM , "NCM"      ,          oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosQuan, "Quant.",             oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,    nPosVUni, "Prc. Unit.",		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVUni, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab,    nPosVTot, "Vlr. Total", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab+10, nPosVTot, "Livre Imp.", 		oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosAIcm, "A.ICMS",             oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosAIpi, "A.IPI",              oFontDetN, 050, 07, , nPadLeft,)
		oPrintPvt:SayAlign(nLinCab, nPosEnt , "Dt. Entrega",        oFontDetN, 050, 07, , nPadLeft,)
	EndIf
	
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
	cTexto := "Pedido: "+QRY_PED->C5_NUM+"    |    "+dToC(dDataBase)+"     "+cHoraEx+"     "+FunName()+"     "+cUserName
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
	
	If cLayout == "1"
		nPosCod  := 0010 //Código do Produto 
		nPosDesc := 0100 //Descricao
		nPosUnid := 0400 //Unidade de Medida
		nPosNCM  := 0435 //NCM
		nPosQuan := 0490 //Quantidade
		nPosVUni := 0530 //Valor Unitario
		nPosVTot := 0580 //Valor Total
		nPosSTVl := 0630 //Valor Unitario + ST
		nPosSTTo := 0680 //Valor Total ST
		nPosAIcm := 0730 //Aliquota ICMS
		nPosEnt  := 0780 //Entrega
		
		oFontDet   := TFont():New(cNomeFont, , -10, , .F.)
		oFontDetN  := TFont():New(cNomeFont, , -10, , .T.)
		
	Else
		nPosCod  := 0010 //Código do Produto 
		nPosDesc := 0100 //Descricao
		nPosUnid := 0400 //Unidade de Medida
		nPosNCM  := 0435 //NCM
		nPosQuan := 0490 //Quantidade
		nPosVUni := 0530 //Valor Unitario
		nPosVTot := 0580 //Valor Total
		nPosAIcm := 0650 //Aliquota ICMS
		nPosAIpi := 0690 //Aliquota IPI
		nPosEnt  := 0740 //Entrega
		
		oFontDet   := TFont():New(cNomeFont, , -10, , .F.)
		oFontDetN  := TFont():New(cNomeFont, , -10, , .T.)
	EndIf
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
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotFrete, cMaskFrete)),         oFontCabN, 080, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+005, "Peso.Liq.:",                                      oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+095, Alltrim(Transform(QRY_PED->C5_PESOL, cMaskPLiq)),  oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total dos Descontos: ",                     oFontCab,  150, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nDesconto, cMaskVlr)),           oFontCabN, 080, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+005, "Peso.Bru:",                                       oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+095, Alltrim(Transform(QRY_PED->C5_PBRUTO, cMaskPBru)), oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total dos Produtos: ",                      oFontCab,  150, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nValorTot, cMaskVlr)),           oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor do ICMS Substituição: ",                    oFontCab,  0150, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotalST, cMaskVlr)),            oFontCabN, 080, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+005, "Valor do IPI:",                                   oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColMeio+095, Alltrim(Transform(nTotIPI, cMaskVlr)),             oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 10
	oPrintPvt:SayAlign(nLinAtu, nColIni+0005, "Valor Total do Pedido: ",                         oFontCab,  080, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinAtu, nColIni+0095, Alltrim(Transform(nTotVal, cMaskVlr)),             oFontCabN, 080, 07, , nPadRight, )
	nLinAtu += 20
Return

/*---------------------------------------------------------------------*
 | Func:  fMsgObs                                                      |
 | Desc:  Funcao para imprimir mensagem de observação                  |
 *---------------------------------------------------------------------*/

Static Function fMsgObs()
	Local aMsg  := {"", "", ""}
	Local nQueb := 100
	Local cMsg  := Alltrim(QRY_PED->C5_MENNOTA)
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

Static Function fMontDupl()
	Local aArea    := GetArea()
	Local lDtEmi   := SuperGetMv("MV_DPDTEMI", .F., .T.)
	Local nAcerto  := 0
	Local aEntr    := {}
	Local aDupl    := {}
	Local aDuplTmp := {}
	Local nItem    := 0
	Local nAux     := 0
	
	aDuplicatas := {}
	
	//Posiciona na condiÃ§Ã£o de pagamento
	DbSelectarea("SE4")
	SE4->(DbSetOrder(1))
	SE4->(DbSeek(xFilial("SE4")+SC5->C5_CONDPAG))
	
	//Se na planilha financeira do Pedido de Venda as duplicatas serÃ£o separadas pela Emissao
	If lDtEmi
		//Se Nao for do tipo 9
		If (SE4->E4_TIPO != "9")
			//Pega as datas e valores das duplicatas
			aDupl := Condicao(MaFisRet(, "NF_BASEDUP"), SC5->C5_CONDPAG, MaFisRet(, "NF_VALIPI"), SC5->C5_EMISSAO, MaFisRet(, "NF_VALSOL"))
			
			//Se tiver dados, percorre os valores e adiciona dados na Ãºltima parcela
			If Len(aDupl) > 0
				For nAux := 1 To Len(aDupl)
					nAcerto += aDupl[nAux][2]
				Next nAux
				aDupl[Len(aDupl)][2] += MaFisRet(, "NF_BASEDUP") - nAcerto
			EndIf
		
		//Adiciona uma Ãºnica linha
		Else
			aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
		EndIf
		
	Else
		//Percorre os itens
		nItem := 0
		QRY_ITE->(DbGoTop())
		While ! QRY_ITE->(EoF())
			nItem++
			
			//Se tiver entrega
			If !Empty(QRY_ITE->C6_ENTREG)
				
				//Procura pela data de entrega no Array
				nPosEntr := Ascan(aEntr, {|x| x[1] == QRY_ITE->C6_ENTREG})
				
				//Se Nao encontrar cria a Linha, do contrÃ¡rio atualiza os valores
 				If nPosEntr == 0
					aAdd(aEntr, {QRY_ITE->C6_ENTREG, MaFisRet(nItem, "IT_BASEDUP"), MaFisRet(nItem, "IT_VALIPI"), MaFisRet(nItem, "IT_VALSOL")})
				Else
					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_BASEDUP")
					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_VALIPI")
					aEntr[nPosEntr][2]+= MaFisRet(nItem, "IT_VALSOL")
				EndIf
			EndIf
			
			QRY_ITE->(DbSkip())
		EndDo
		
		//Se Nao for CondiÃ§Ã£o do tipo 9
		If (SE4->E4_TIPO != "9")
			
			//Percorre os valores conforme data de entrega
			For nItem := 1 to Len(aEntr)
				nAcerto  := 0
				aDuplTmp := Condicao(aEntr[nItem][2], SC5->C5_CONDPAG, aEntr[nItem][3], aEntr[nItem][1], aEntr[nItem][4])
				
				//Atualiza o valor da Ãºltima parcela
				For nAux := 1 To Len(aDuplTmp)
					nAcerto += aDuplTmp[nAux][2]
				Next nAux
				aDuplTmp[Len(aDuplTmp)][2] += aEntr[nItem][2] - nAcerto
				
				//Percorre o temporÃ¡rio e adiciona no duplicatas
				aEval(aDuplTmp, {|x| aAdd(aDupl, {aEntr[nItem][1], x[1], x[2]})})
			Next
			
		Else
	    	aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
		EndIf
	EndIf
	
	//Se Nao tiver duplicatas, adiciona em branco
	If Len(aDupl) == 0
		aDupl := {{Ctod(""), MaFisRet(, "NF_BASEDUP"), PesqPict("SE1", "E1_VALOR")}}
	EndIf
	
	aDuplicatas := aClone(aDupl)
	RestArea(aArea)
Return

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
	oPrintPvt:SayAlign(nLinAtu-10, nColIni, "Condicao de Pagamento:  " +QRY_PED->E4_DESCRI, 									oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
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
