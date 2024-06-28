### Docker

「よーし、なんか作ろっかなー」と思って、とりあえず  
Dockerでの仮想環境の作り方を調べることから毎回始まってるので、  
ここらで一回まとめておこうと思います！

### 始めに
- dockerとdocker-composeをインストールされていることを前提に進めてます。

### Dockerfile
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

### requirements.txt
- 説明
  - pipでインストールするパッケージを書くファイル
- 使用例
  ```
  Flask==1.1.2
  ```



### docker-compose.yml
