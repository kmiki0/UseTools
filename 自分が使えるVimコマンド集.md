#### カウントアップ
`Ctrl + a`
#### カウントダウン
`Ctrl + x`

## テキストエディタ内のコマンド
- `:e fileName.txt` 新規保存する。

## vimのマーク機能について

- マークの設定方法  
`m + [a-zA-Z]` でマークを設定できる。

- 移動方法  
`'a` でマーク a にジャンプできる。

- マークの確認方法  
`:marks` で設定したマークを確認できる。

- マークの削除方法  
`:delmarks [a-zA-Z]` でマークを削除できる。  
`:delmarks!` で全てのマークを削除できる。


#### VisualStudioのvsVim設定

##### Defaults
- General
    - Default Settings 
        - GVim73
    - Display Control Characters
        - True
    - Hide Marks
    - Output Window
        - True
    - Rename and Snippet Tracking
        - True
    - Use Editor Command Margin
        - True
    - VimRc Error Reporting
        - False
    - VimRc File Loading
        - vsvimrc or vimrc files
    - Word Wrap Display
        - AutoIndent + Glyph

- Vim Edit Behavior
    - Crean Macro Recording
        - False
    - Report Clipboard Errors
        - False
    - Use Visual Studio Indent
        - True
    - Use Visual Studio Settings
        - True
    - Use Visual Studio Tab/Bacspace
        - True

##### Kyeboard
- Handled by Visual Studio
    - Ctrl + L
    - Ctrl + M
    - Ctrl + V
