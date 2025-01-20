//Bibliotecas
#Include 'totvs.ch'

#Define ENTER Chr(13)+Chr(10)

/*/{Protheus.doc} PE01NFESEFAZ
Ponto de entrada localizado na função XmlNfeSef do rdmake NFESEFAZ. 
Através deste ponto é possível realizar manipulações nos dados do produto, 
mensagens adicionais, destinatário, dados da nota, pedido de venda ou compra, antes da 
montagem do XML, no momento da transmissão da NFe.
@author TOTVS NORDESTE (Elvis Siqueira)
@since 23/10/2024
@version 1.0
    @return Nil
        PE01NFESEFAZ - Manipulação em dados do produto ( [ aParam ] ) --> aRetorno
    @example
        Nome	 	 	Tipo	 	 	    Descrição	 	 	                        	 
 	    aParam   	 	Array of Record	 	aProd     := PARAMIXB[1]
                                            cMensCli  := PARAMIXB[2]
                                            cMensFis  := PARAMIXB[3]
                                            aDest     := PARAMIXB[4]
                                            aNota     := PARAMIXB[5]
                                            aInfoItem := PARAMIXB[6]
                                            aDupl     := PARAMIXB[7]
                                            aTransp   := PARAMIXB[8]
                                            aEntrega  := PARAMIXB[9]
                                            aRetirada := PARAMIXB[10]
                                            aVeiculo  := PARAMIXB[11]
                                            aReboque  := PARAMIXB[12]
                                            aNfVincRur:= PARAMIXB[13]
                                            aEspVol   := PARAMIXB[14]
                                            aNfVinc   := PARAMIXB[15]
                                            aDetPag   := PARAMIXB[16]
                                            aObsCont  := PARAMIXB[17]
                                            aProcRef  := PARAMIXB[18]
    @obs https://tdn.totvs.com/pages/viewpage.action?pageId=274327446
/*/

User Function PE01NFESEFAZ()
    Local aProd     := PARAMIXB[1]
    Local cMensCli  := PARAMIXB[2]
    Local cMensFis  := PARAMIXB[3]
    Local aDest     := PARAMIXB[4] 
    Local aNota     := PARAMIXB[5]
    Local aInfoItem := PARAMIXB[6]
    Local aDupl     := PARAMIXB[7]
    Local aTransp   := PARAMIXB[8]
    Local aEntrega  := PARAMIXB[9]
    Local aRetirada := PARAMIXB[10]
    Local aVeiculo  := PARAMIXB[11]
    Local aReboque  := PARAMIXB[12]
    Local aNfVincRur:= PARAMIXB[13]
    Local aEspVol   := PARAMIXB[14]
    Local aNfVinc   := PARAMIXB[15]
    Local adetPag   := PARAMIXB[16]
    Local aObsCont  := PARAMIXB[17]
    Local aProcRef  := PARAMIXB[18]
    Local aRetorno  := {}

    Local aAreaSD2	:= SD2->(FWGetArea())
    Local aAreaSD1	:= SD1->(FWGetArea())
    Local aAreaSB8	:= SB8->(FWGetArea())
    Local aAreaSF1  := SF1->(FWGetArea())

    Local cPictQtd  := PesqPict("SD2","D2_QUANT")
    Local cPictQtdSd1 := PesqPict("SD1","D1_QUANT")
    Local nVolume   := 0
    Local _nI

    DBSelectArea("SD2")
    SD2->(DBSetOrder(3)) 

    DBSelectArea("SD1")
    SD1->(DBSetOrder(1)) 

    DBSelectArea("SB8")
    SB8->(DBSetOrder(5))

    If aNota[4] == "1" // Se for Nota Fiscal de Saída 
        
        //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        //@ Bloco responsável por acrescenta o Número do LOTE. ///// INICIO /////
        For _nI := 1  to Len(aProd)
            
            SD2->(MsSeek(xFilial("SD2")+aNota[2]+aNota[1]+aNota[7]+aNota[8]+aProd[_nI][2]+STrZero(aProd[_nI][1],2))) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
            
            If !Empty(SD2->D2_QTSEGUM) //Segunda Unidade de Medida
                aProd[_nI][9]  := SD2->D2_QTSEGUM
                aProd[_nI][12] := SD2->D2_QTSEGUM
                If !Empty(SD2->D2_SEGUM)
                    aProd[_nI][8]  := SD2->D2_SEGUM
                    aProd[_nI][11] := SD2->D2_SEGUM
                EndIF
            EndIF 

            nVolume += aProd[_nI,9] //Soma a quantidade dos produtos 

            If !Empty(SD2->D2_PEDIDO)
                DBSelectArea("SC6")
                SC6->(DBSetOrder(2))
                IF SC6->(MsSeek(xFilial("SC6") + aProd[_nI][2] + SD2->D2_PEDIDO ))
                    If !Empty(SC6->C6_PEDCLI)
                        aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;Pedido: " + Alltrim(SC6->C6_PEDCLI)
                    EndIF
                EndIF
            EndIF 

            If !Empty(SD2->D2_LOTECTL)
                aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;LOTE: " + Alltrim(SD2->D2_LOTECTL)
                aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;QTD: " + AllTrim(AllToChar(aProd[_nI,9],cPictQtd))
            EndIF

            If !Empty(SD2->D2_DTVALID)
                If SB8->(MsSeek(xFilial("SB8") + SD2->D2_COD + SD2->D2_LOTECTL ))
                    aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;FAB: " + DToC(SB8->B8_DFABRIC)
                EndIF 
                aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;VAL: " + DToC(SD2->D2_DTVALID)
            EndIF 

        Next _nI
        //@ Bloco responsável por acrescenta o Número do LOTE.
        //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    Else
 
        For _nI := 1  to Len(aProd)
            
            SD1->(MsSeek(xFilial("SD1") + aNota[2] +aNota[1] +aNota[7]+ aNota[8] + aProd[_nI][2]+STrZero(aProd[_nI][1],2))) //Filial + Documento + Serie + Forn/Cliente + Loja + Produto + Item NF	

            If !Empty(SD1->D1_LOTECTL)  
                aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;LOTE: " + Alltrim(SD1->D1_LOTECTL)
                aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;QTD: " + AllTrim(AllToChar(aProd[_nI,9],cPictQtdSd1))
            EndIF

            If !Empty(SD1->D1_DTVALID)
                If SB8->(MsSeek(xFilial("SB8") + SD1->D1_COD + SD1->D1_LOTECTL ))
                    aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;FAB: " + DToC(SB8->B8_DFABRIC)
                EndIF 
                aProd[_nI][4] := Alltrim(aProd[_nI][4]) + " ;VAL: " + DToC(SD1->D1_DTVALID)
            EndIF 

        Next _nI
        //@ Bloco responsável por acrescenta o Número do LOTE e Validade na Devolução
        //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------


        DbSelectArea("SF1")
        IF SF1->(MsSeek(xFilial("SF1")+aNota[2]+aNota[1]+aNota[7]+aNota[8]))
            If !Empty(SF1->F1_MOTRET) 
                cMensCli += " MOTIVO: " + AllTrim(Posicione('DHI', 1, FWxFilial('DHI') + F1_MOTRET, 'DHI_DESCRI'))
            EndIf
        EndIF 
    EndIF
        //@ Bloco responsável por acrescenta o Motivo do retorno. ///// FIM /////
        //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    If !Empty(aEspVol)
        aEspVol[1,2] := nVolume
    EndIF

    FWRestArea(aAreaSD2)
    FWRestArea(aAreaSD1)
    FWRestArea(aAreaSB8)
    FWRestArea(aAreaSF1)

    aadd(aRetorno,aProd)
    aadd(aRetorno,cMensCli)
    aadd(aRetorno,cMensFis)
    aadd(aRetorno,aDest)
    aadd(aRetorno,aNota)
    aadd(aRetorno,aInfoItem)
    aadd(aRetorno,aDupl)
    aadd(aRetorno,aTransp)
    aadd(aRetorno,aEntrega)
    aadd(aRetorno,aRetirada)
    aadd(aRetorno,aVeiculo)
    aadd(aRetorno,aReboque)
    aadd(aRetorno,aNfVincRur)
    aadd(aRetorno,aEspVol)
    aadd(aRetorno,aNfVinc)
    aadd(aRetorno,AdetPag)
    aadd(aRetorno,aObsCont)
    aadd(aRetorno,aProcRef) 

Return aRetorno
