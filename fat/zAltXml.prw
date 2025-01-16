//Bibliotecas
#Include "TOTVS.ch"
 
/*/{Protheus.doc} User Function PE01NFESEFAZ

Ponto de entrada antes da montagem dos dados da transmissão da NFE
Processo atendido: Inclusão do campo de Motivo de retorno (F1_HISTRET) no XML e consequentemente na DANFE.

    [01] = aProd
    [02] = cMensCli
    [03] = cMensFis
    [04] = aDest
    [05] = aNota
    [06] = aInfoItem
    [07] = aDupl
    [08] = aTransp
    [09] = aEntrega
    [10] = aRetirada
    [11] = aVeiculo
    [12] = aReboque
    [13] = aNfVincRur
    [14] = aEspVol
    [15] = aNfVinc
    [16] = aDetPag
    [17] = aObsCont
    [18] = aProcRef
    [19] = aMed
    [20] = aLote
/*/
 
User Function PE01NFESEFAZ()
    Local aArea    := FWGetArea()
    Local aAreaSF1 := SF1->(FWGetArea())
    Local aDados   := PARAMIXB
    Local cMsgAux  := ""
 
    // Caso haja algum motivo de retorno
    If ! Empty(SF1->F1_HISTRET)
         
        DbSelectArea("SF1")
        DbSetOrder(1)
            //Monta a mensagem
            cMsgAux += "MOTIVO" + SF1->F1_HISTRET
            //Incrementa na mensagem que irá para o xml e danfe
            aDados[02] += cMsgAux
    EndIf
 
    FWRestArea(aAreaSF1)
    FWRestArea(aArea)
Return aDados
