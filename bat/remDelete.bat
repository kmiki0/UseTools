
@echo off
setlocal enabledelayedexpansion

rem === SearchList.txt �̓ǂݍ��� ===
set "search_list=SearchList.txt"
if not exist "%search_list%" (
    echo �t�@�C�� %search_list% ��������܂���B
    exit /b
)

rem === �����Ώۃt�H���_�̎w�� ===
set "target_folder=.\target"

rem === ���K�\���Ō������镶�� ===
set "search_pattern=REM C:\\dx_ap\\NISMAIL_1\\"

rem === SearchList.txt �̓��e��1�s���ǂݍ��� ===
for /f "usebackq delims=" %%F in ("%search_list%") do (
    set "file_name=%%F"
    set "file_path=%target_folder%\!file_name!"
    set "file_path=!file_path: =!"

    rem === �w�肳�ꂽ�t�@�C�����t�H���_���ɑ��݂��邩�m�F ===
    if exist "!file_path!" (
        echo !file_path! ���`�F�b�N��...

        rem === �t�@�C�����̓��e������ ===
        set "found_line="
        for /f "delims=" %%L in ('chcp 65001 ^& type "!file_path!" ^& find /i "%search_pattern%" "!file_path!" 2^>nul') do (

            set "found_line=%%L"

            echo !found_line! | findstr /b /c:"%search_pattern%" >nul && (
                echo !found_line!
                rem === ���[�U�[�� Yes/No ��I�������� ===
                set "user_input="
                set /p "user_input=���̍s�� "REM " ���폜���܂����H (y/n): "

                if /i "!user_input!"=="y" (
                    rem === "REM " ���폜�������e�ňꎞ�t�@�C�����쐬 ===
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

                    rem === �ꎞ�t�@�C�����猳�t�@�C���ɒu������ ===
                    if not errorlevel 1 (
                        move /y "!file_path!.tmp" "!file_path!" >nul
                        echo �C�����������܂����B
                    ) else (
                        echo �t�@�C���̍X�V�Ɏ��s���܂����B
                    )
                ) else (
                    echo �C�����X�L�b�v���܂����B
                )
            ) 
        )
    ) else (
        echo !file_path! �͌�����܂���B
    )
)

echo bat end

pause

