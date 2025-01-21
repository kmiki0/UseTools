Attribute VB_Name = "Module1"
Sub �t�H���_���̃t�@�C���X�V���t�`�F�b�N()
    Dim folderPath As String
    Dim filePath As String
    Dim fileName As String
    Dim fileDate As Date
    Dim lastRow As Long
    Dim ws As Worksheet
    
    ' �t�H���_�̃p�X���w��i��FC:\temp\�j
    folderPath = "C:\Users\batch\"
    
    ' �t�H���_�̖����Ɂu\\�v���Ȃ���Βǉ�
    If Right(folderPath, 1) <> "\\" Then
        folderPath = folderPath & "\\"
    End If
    
    ' ���[�N�V�[�g�ݒ�
    Set ws = ThisWorkbook.Sheets("Sheet1")
    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row
    
    ' C��̒l��B��Ɉړ�
    Dim i As Long
    For i = 2 To lastRow
        ws.Cells(i, 2).Value = ws.Cells(i, 3).Value
    Next i
    
    ' �t�H���_���̂��ׂẴt�@�C��������
    filePath = Dir(folderPath & "*.*")
    Do While filePath <> ""
        ' �t�@�C�����i�g���q�Ȃ��j���擾
        fileName = Left(filePath, InStrRev(filePath, ".") - 1)
        fileDate = FileDateTime(folderPath & filePath)
        
        Dim found As Range
        Set found = ws.Columns("A").Find(fileName, LookAt:=xlWhole)
        
        If Not found Is Nothing Then
            ' �X�V����C��ɋL��
            found.Offset(0, 2).Value = fileDate
            found.Offset(0, 2).NumberFormat = "yyyy/mm/dd hh:mm:ss"
            
            ' B���C��̔�r
            If found.Offset(0, 1).Value <> found.Offset(0, 2).Value Then
                found.Offset(0, 3).Value = "��"
                found.Offset(0, 3).Interior.Color = RGB(255, 0, 0) ' �ԐF�n�C���C�g
            Else
                found.Offset(0, 3).Value = ""
                found.Offset(0, 3).Interior.ColorIndex = xlNone
            End If
        Else
            ' �V�����t�@�C�����ŏI�s�ɒǉ�
            lastRow = lastRow + 1
            ws.Cells(lastRow, 1).Value = fileName
            ws.Cells(lastRow, 3).Value = fileDate
            ws.Cells(lastRow, 3).NumberFormat = "yyyy/mm/dd hh:mm:ss"
        End If
        
        filePath = Dir()
    Loop
    
    MsgBox "�������������܂���", vbInformation
End Sub

