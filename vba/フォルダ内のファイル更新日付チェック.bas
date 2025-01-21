Attribute VB_Name = "Module1"
Sub フォルダ内のファイル更新日付チェック()
    Dim folderPath As String
    Dim filePath As String
    Dim fileName As String
    Dim fileDate As Date
    Dim lastRow As Long
    Dim ws As Worksheet
    
    ' フォルダのパスを指定（例：C:\temp\）
    folderPath = "C:\Users\batch\"
    
    ' フォルダの末尾に「\\」がなければ追加
    If Right(folderPath, 1) <> "\\" Then
        folderPath = folderPath & "\\"
    End If
    
    ' ワークシート設定
    Set ws = ThisWorkbook.Sheets("Sheet1")
    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row
    
    ' C列の値をB列に移動
    Dim i As Long
    For i = 2 To lastRow
        ws.Cells(i, 2).Value = ws.Cells(i, 3).Value
    Next i
    
    ' フォルダ内のすべてのファイルを処理
    filePath = Dir(folderPath & "*.*")
    Do While filePath <> ""
        ' ファイル名（拡張子なし）を取得
        fileName = Left(filePath, InStrRev(filePath, ".") - 1)
        fileDate = FileDateTime(folderPath & filePath)
        
        Dim found As Range
        Set found = ws.Columns("A").Find(fileName, LookAt:=xlWhole)
        
        If Not found Is Nothing Then
            ' 更新日をC列に記載
            found.Offset(0, 2).Value = fileDate
            found.Offset(0, 2).NumberFormat = "yyyy/mm/dd hh:mm:ss"
            
            ' B列とC列の比較
            If found.Offset(0, 1).Value <> found.Offset(0, 2).Value Then
                found.Offset(0, 3).Value = "○"
                found.Offset(0, 3).Interior.Color = RGB(255, 0, 0) ' 赤色ハイライト
            Else
                found.Offset(0, 3).Value = ""
                found.Offset(0, 3).Interior.ColorIndex = xlNone
            End If
        Else
            ' 新しいファイルを最終行に追加
            lastRow = lastRow + 1
            ws.Cells(lastRow, 1).Value = fileName
            ws.Cells(lastRow, 3).Value = fileDate
            ws.Cells(lastRow, 3).NumberFormat = "yyyy/mm/dd hh:mm:ss"
        End If
        
        filePath = Dir()
    Loop
    
    MsgBox "処理が完了しました", vbInformation
End Sub

