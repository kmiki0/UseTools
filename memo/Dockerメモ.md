# DockerFileの項目説明

「よーし、なんか作ろっかなー」と思って、とりあえず  
Dockerでの仮想環境の作り方を調べることから毎回始まってるので、  
ここらで一回まとめておこうと思います！

## はじめに
- これは個人的なメモで、主にコマンドの説明をしてます。  
- 仮想環境の手順を見たい方は、他の方の記事を参考にしてください。

## Dockerfile
- 説明
  - 使用するイメージや、コンテナ内での作業を書くファイル
  - pipインストールは、requirements.txtを使うことが多い

- よく使うコマンド
  - `FROM`
    - 使用するイメージを指定する

    ```Dockerfile
    FROM python:3.8
    ```

  - `RUN`
    - コンテナ内で実行するコマンドを書く
    - apt-getでパッケージをインストールするときに使う

      > apt-get は、先に `apt-get update` を実行する必要があるが、
      > installと別々のRUNコマンドで実行すると、キャッシュに問題発生することがあるので、一つにまとめるたほうがいい

    ```Dockerfile
    RUN apt-get update && apt-get install -y \
      vim \
      git
    ```

  - `COPY`
    - ローカルファイルをコンテナ内に持っていきたいときに使う

    ```Dockerfile
    COPY ./app /app
    ```

  - `CMD`
    - コンテナ起動時に実行するコマンドを書く

    ```Dockerfile
    CMD ["python", "app.py"]
    ```

  - `USER`
    - コンテナ内でのユーザーを指定する

    ```Dockerfile
    # ユーザーとグループはビルド時に指定する
    ARG UID
    ARG GID
    
    # ユーザーとグループを作成
    RUN groupadd -g ${UID} dev && \
        useradd -l -u ${GID} -g dev dev && \
        install -d -m 0755 -o dev -g dev /home/dev
    
    USER dev
    ```

    コンテナを作成するときに、ユーザーIDとグループIDを指定することで、  
    コンテナ内でのユーザーをホストと同じにすることが出来る

    ```bash
        # Dockerイメージのビルド
        docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t myimage .
    ```


## requirements.txt
- 説明
  - pipでインストールするパッケージを書くファイル
  - Dockerfile内で、requirements.txtを使ってパッケージをインストールすることが多い

- 使用例
  ```
  # pipインストールするパッケージ
  requests
  Flask==1.1.2
  selenium>=1.0,<=2.0
  ```
- このファイルの書き方
   - == や >= 等の比較演算子を使うことでバージョンの指定が出来る。  
   - パッケージ名のみを指定すると最新バージョンがインストールされる。  
   - ,(カンマ)で区切ると、バージョンの範囲指定が出来る。  
   - \# でコメントアウトが出来る。


- 使い方
  - Dockerfile内で、`RUN pip install -r requirements.txt` と書くことで、  
    requirements.txtに書かれたパッケージをインストールすることが出来る。

