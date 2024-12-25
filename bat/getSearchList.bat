@echo off
setlocal enabledelayedexpansion

rem === 設定: 抽出対象フォルダと条件 ===
set "target_folder=.\target"          rem 抽出対象のフォルダ
set "output_file=SearchList.txt"      rem 出力先ファイル
set "file_extension=*.bat"            rem 対象ファイルの拡張子
set "exclude_keywords=bk2024 メモ"    rem 除外キーワード (スペース区切りで指定)
set "filename_length=5"               rem 抽出するファイル名の文字数 (拡張子を除く)

rem === SearchList.txt の初期化または新規作成 ===
if exist "%output_file%" (
    > "%output_file%" echo.
) else (
    echo SearchList.txt を新規作成します。
    type nul > "%output_file%"
)

rem === ファイル数カウンターを初期化 ===
set "file_count=0"

rem === 対象ファイルを抽出 ===
for /f "delims=" %%F in ('dir /b "%target_folder%\%file_extension%" ^| findstr /v /i "%exclude_keywords%"') do (
    set "file_name=%%F"
    if "!file_name:~%filename_length%!"==".bat" (
        echo %%F
        echo %%F >> "%output_file%"
        set /a file_count+=1
    )
)

echo 結果 ファイル数: %file_count%

pause
