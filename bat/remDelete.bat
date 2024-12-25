
@echo off
setlocal enabledelayedexpansion

rem === SearchList.txt の読み込み ===
set "search_list=SearchList.txt"
if not exist "%search_list%" (
    echo ファイル %search_list% が見つかりません。
    exit /b
)

rem === 検索対象フォルダの指定 ===
set "target_folder=.\target"

rem === 正規表現で検索する文言 ===
set "search_pattern=REM C:\\dx_ap\\NISMAIL_1\\"

rem === SearchList.txt の内容を1行ずつ読み込む ===
for /f "usebackq delims=" %%F in ("%search_list%") do (
    set "file_name=%%F"
    set "file_path=%target_folder%\!file_name!"
    set "file_path=!file_path: =!"

    rem === 指定されたファイルがフォルダ内に存在するか確認 ===
    if exist "!file_path!" (
        echo !file_path! をチェック中...

        rem === ファイル内の内容を検索 ===
        set "found_line="
        for /f "delims=" %%L in ('chcp 65001 ^& type "!file_path!" ^& find /i "%search_pattern%" "!file_path!" 2^>nul') do (

            set "found_line=%%L"

            echo !found_line! | findstr /b /c:"%search_pattern%" >nul && (
                echo !found_line!
                rem === ユーザーに Yes/No を選択させる ===
                set "user_input="
                set /p "user_input=この行の "REM " を削除しますか？ (y/n): "

                if /i "!user_input!"=="y" (
                    rem === "REM " を削除した内容で一時ファイルを作成 ===
                    (
                        for /f "delims=" %%A in ('type "!file_path!"') do (
                            set "line=%%A"
                            echo !line! | findstr /b /c:"REM " >nul && (
                                echo !line:REM =!
                            ) || (
                                echo !line!
                            )
                        )
                    ) > "!file_path!.tmp"

                    rem === 一時ファイルから元ファイルに置き換え ===
                    if not errorlevel 1 (
                        move /y "!file_path!.tmp" "!file_path!" >nul
                        echo 修正が完了しました。
                    ) else (
                        echo ファイルの更新に失敗しました。
                    )
                ) else (
                    echo 修正をスキップしました。
                )
            ) 
        )
    ) else (
        echo !file_path! は見つかりません。
    )
)

echo bat end

pause

