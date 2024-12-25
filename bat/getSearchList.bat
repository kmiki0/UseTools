@echo off
setlocal enabledelayedexpansion

rem === �ݒ�: ���o�Ώۃt�H���_�Ə��� ===
set "target_folder=.\target"          rem ���o�Ώۂ̃t�H���_
set "output_file=SearchList.txt"      rem �o�͐�t�@�C��
set "file_extension=*.bat"            rem �Ώۃt�@�C���̊g���q
set "exclude_keywords=bk2024 ����"    rem ���O�L�[���[�h (�X�y�[�X��؂�Ŏw��)
set "filename_length=5"               rem ���o����t�@�C�����̕����� (�g���q������)

rem === SearchList.txt �̏������܂��͐V�K�쐬 ===
if exist "%output_file%" (
    > "%output_file%" echo.
) else (
    echo SearchList.txt ��V�K�쐬���܂��B
    type nul > "%output_file%"
)

rem === �t�@�C�����J�E���^�[�������� ===
set "file_count=0"

rem === �Ώۃt�@�C���𒊏o ===
for /f "delims=" %%F in ('dir /b "%target_folder%\%file_extension%" ^| findstr /v /i "%exclude_keywords%"') do (
    set "file_name=%%F"
    if "!file_name:~%filename_length%!"==".bat" (
        echo %%F
        echo %%F >> "%output_file%"
        set /a file_count+=1
    )
)

echo ���� �t�@�C����: %file_count%

pause
