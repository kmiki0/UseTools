Sub CheckLatestFileFromSheet()
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim folderPath As String
    Dim fileName As String
    Dim latestFile As String
    Dim latestTimestamp As String
    Dim currentDate As String
    Dim fso As Object
    Dim filePath As String
    Dim lineCount As Integer
    Dim fileContent As String
    Dim i As Long
    
    ' シートの指定（必要に応じて変更）
    Set ws = ThisWorkbook.Sheets(1)

    ' 最終行を取得（A列にファイル名があると仮定）
    lastRow = ws.Cells(ws.Rows.Count, "A").End(xlUp).Row

    ' 現在の日付（yyyymmdd）
    currentDate = Format(Date, "yyyymmdd")

    ' FileSystemObject の作成
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' 最新のファイル情報を初期化
    latestFile = ""
    latestTimestamp = ""

    ' A列とB列のデータをループ処理
    For i = 2 To lastRow
        fileName = ws.Cells(i, 1).Value  ' A列：ファイル名
        folderPath = ws.Cells(i, 2).Value ' B列：フォルダパス

        ' フォルダパスの末尾に "\" を補完
        If Right(folderPath, 1) <> "\" Then folderPath = folderPath & "\"

        ' ファイル名の形式チェック（先頭17桁が yyyymmddhhmmssSSS）
        If IsNumeric(Left(fileName, 17)) And Len(fileName) >= 17 Then
            Dim fileDate As String
            fileDate = Left(fileName, 8) ' yyyymmdd 部分を取得

            ' 最新ファイルの更新チェック
            If latestTimestamp < Left(fileName, 17) Then
                latestTimestamp = Left(fileName, 17)
                latestFile = folderPath & fileName
            End If
        End If
    Next i

    ' 最新ファイルの日付部分（yyyymmdd）と現在日付を比較
    If Left(latestTimestamp, 8) = currentDate Then
        ' 最新ファイルのパスを確認
        If fso.FileExists(latestFile) Then
            ' ファイルの行数を取得（ヘッダーを除外）
            Open latestFile For Input As #1
            lineCount = -1 ' ヘッダー分を引くため初期値 -1
            Do While Not EOF(1)
                Line Input #1, fileContent
                lineCount = lineCount + 1
            Loop
            Close #1

            MsgBox "最新ファイル: " & latestFile & vbCrLf & _
                   "レコード件数: " & lineCount, vbInformation
        Else
            MsgBox "ファイルが見つかりません: " & latestFile, vbExclamation
        End If
    Else
        MsgBox "本日の日付 (" & currentDate & ") に一致するファイルがありません。", vbExclamation
    End If

    ' オブジェクト解放
    Set fso = Nothing
End Sub
