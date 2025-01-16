//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

//Variaveis
Static nPadLeft   := 0                                                                     //Alinhamento a Esquerda
Static nPadRight  := 1                                                                     //Alinhamento a Direita
Static nPadCenter := 2                                                                     //Alinhamento Centralizado
Static nPosCod    := 0000                                                                  //Posi��o Inicial da Coluna de C�digo do Produto 
Static nPosDesc   := 0000                                                                  //Posi��o Inicial da Coluna de Descri��o
Static nPosNCM    := 0000                                                                  //Posi��o Inicial da Coluna de NCM
Static nPosUnid   := 0000                                                                  //Posi��o Inicial da Coluna de Unidade de Medida
Static nPosQuan   := 0000                                                                  //Posi��o Inicial da Coluna de Quantidade
Static nPosVUni   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Unitario
Static nPosVTot   := 0000                                                                  //Posi��o Inicial da Coluna de Valor Total
Static nTamFundo  := 15                                                                    //Altura de fundo dos blocos com t�tulo
Static cEmpEmail  := Alltrim(SuperGetMV("MV_X_EMAIL", .F., "email@empresa.com.br"))        //Par�metro com o e-Mail da empresa
Static cEmpSite   := Alltrim(SuperGetMV("MV_X_HPAGE", .F., "http://www.empresa.com.br"))   //Par�metro com o site da empresa
Static nCorAzul   := RGB(89, 111, 117)                                                     //Cor Azul usada nos T�tulos
Static cNomeFont  := "Arial"                                                               //Nome da Fonte Padr�o
Static oFontDet   := Nil                                                                   //Fonte utilizada na Impress�o dos itens
Static oFontDetN  := Nil                                                                   //Fonte utilizada no cabeçalho dos itens
Static oFontRod   := Nil                                                                   //Fonte utilizada no rodape da P�gina
Static oFontTit   := Nil                                                                   //Fonte utilizada no T�tulo das se��es
Static oFontCab   := Nil                                                                   //Fonte utilizada na Impress�o dos textos dentro das se��es
Static oFontCabN  := Nil                                                                   //Fonte negrita utilizada na Impress�o dos textos dentro das se��es
Static cMaskPad   := "@E 999,999.99"                                                       //M�scara padr�o de valor 
Static cMaskTel   := "@R (99)99999999"                                                    //M�scara de telefone / fax
Static cMaskCNPJ  := "@R 99.999.999/9999-99"                                               //M�scara de CNPJ
Static cMaskCEP   := "@R 99999-999"                                                        //M�scara de CEP
Static cMaskCPF   := "@R 999.999.999-99"                                                   //M�scara de CPF
Static cMaskQtd   := PesqPict("SC6", "C6_QTDVEN")                                          //M�scara de quantidade
Static cMaskPrc   := PesqPict("SC6", "C6_VALOR")                                          //M�scara de pre�o
Static cMaskVlr   := PesqPict("SC6", "C6_VALOR")                                           //M�scara de valor
Static cMaskFrete := PesqPict("SC5", "C5_FRETE")                                           //M�scara de frete
Static cMaskPBru  := PesqPict("SC5", "C5_PBRUTO")                                          //M�scara de peso bruto
Static cMaskPLiq  := PesqPict("SC5", "C5_PESOL")                                           //M�scara de peso liquido

/*/{Protheus.doc} zROrcamento
Impress�o do or�amento
@type function
@author Atilio
@since 19/06/2016
@version 1.0
	@example
	u_zRPedVen()
/*/

User Function zROrcamento()
	Local aArea      := GetArea()
	Local aAreaC5    := SC5->(GetArea())
	Local aPergs     := {}
	Local aRetorn    := {}
	Local oProcess   := Nil
	//Variaveis usadas nas outras fun��es
	Private cLogoEmp := fLogoEmp()
	Private cPedDe   := SC5->C5_NUM
	Private cPedAt   := SC5->C5_NUM
	Private cLayout  := "1"
	Private cTipoBar := "3"
	Private cImpDupl := "1"
	Private cZeraPag := "1"
	
	//Adiciona os par�metro para a pergunta
	aAdd(aPergs, {1, "Pedido De",  cPedDe, "", ".T.", "SC5", ".T.", 80, .T.})
	aAdd(aPergs, {1, "Pedido Ate", cPedAt, "", ".T.", "SC5", ".T.", 80, .T.})
	aAdd(aPergs, {2, "Layout",                         Val(cLayout),  {"1=Dados com ST",     "2=Dados com IPI"},                                       100, ".T.", .F.})
	aAdd(aPergs, {2, "C�digo de Barras",               Val(cTipoBar), {"1=N�mero do Pedido", "2=Filial + N�mero do Pedido", "3=Sem C�digo de Barras"}, 100, ".T.", .F.})
	aAdd(aPergs, {2, "Imprimir Previs�o Duplicatas",   Val(cImpDupl), {"1=Sim",              "2=Nao"},                                                 100, ".T.", .F.})
	aAdd(aPergs, {2, "Zera a P�gina ao trocar Pedido", Val(cZeraPag), {"1=Sim",              "2=Nao"},                                                 100, ".T.", .F.})
	
	//Se a pergunta for confirmada
	If ParamBox(aPergs, "Informe os par�metro", @aRetorn, , , , , , , , .F., .F.)
		cPedDe   := aRetorn[1]
		cPedAt   := aRetorn[2]
		cLayout  := cValToChar(aRetorn[3])
		cTipoBar := cValToChar(aRetorn[4])
		cImpDupl := cValToChar(aRetorn[5])
		cZeraPag := cValToChar(aRetorn[6])
		
		//Funcao que muda alinhamento e fontes
		fMudaLayout()
		
		//Chama o processamento do relat�rio
		oProcess := MsNewProcess():New({|| fMontaRel(@oProcess) }, "Impress�o Pedidos de Venda", "Processando", .F.)
		oProcess:Activate()
	EndIf
	
	RestArea(aAreaC5)
	RestArea(aArea)
Return
