Sub フォルダ内のファイル更新日付チェック()
    Dim folderPath As String
    Dim filePath As String
    Dim fileName As String
    Dim fileDate As Date
    Dim lastRow As Long
    Dim ws As Worksheet
    
    ' ワークシート設定
    Set ws = ThisWorkbook.Sheets("Sheet1")
    lastRow = ws.Cells(ws.Rows.Count, "D").End(xlUp).Row
    
    ' F列の値をE列に移動
    Dim i As Long
    For i = 2 To lastRow
        ws.Cells(i, 5).Value = ws.Cells(i, 6).Value
    Next i
    
    ' フォルダ内のすべてのファイルを処理
    For i = 2 To lastRow
        folderPath = ws.Cells(i, 2).Value
        If Right(folderPath, 1) <> "\\" Then
            folderPath = folderPath & "\\"
        End If
        
        fileName = "NORMAL_" & ws.Cells(i, 4).Value & ".log"
        filePath = folderPath & fileName
        
        If Dir(filePath) = "" Then
            fileName = "NORMAL_" & ws.Cells(i, 4).Value & "_SEND.log"
            filePath = folderPath & fileName
        End If
        
        If Dir(filePath) <> "" Then
            fileDate = FileDateTime(filePath)
            ws.Cells(i, 6).Value = fileDate
            ws.Cells(i, 6).NumberFormat = "yyyy/mm/dd hh:mm:ss"
            
            ' E列とF列の比較
            If ws.Cells(i, 5).Value <> ws.Cells(i, 6).Value Then
                ws.Cells(i, 7).Value = "○"
                ws.Cells(i, 7).Interior.Color = RGB(144, 238, 144) ' 薄い緑
            Else
                ws.Cells(i, 7).Value = ""
                ws.Cells(i, 7).Interior.ColorIndex = xlNone
            End If
        Else
            ws.Cells(i, 6).Value = "ファイル未発見"
        End If
    Next i
    
    MsgBox "処理が完了しました", vbInformation
End Sub
