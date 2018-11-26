FROM microsoft/mssql-tools as mssql
FROM rockyuan/php7-fpm-alpine:dev
LABEL name='php7-fpm-alpine-mssql-ori' tag='dev' maintainer='RockYuan <RockYuan@gmail>'

# 复制mssql的所需
COPY --from=mssql /opt/microsoft/ /opt/microsoft/
COPY --from=mssql /opt/mssql-tools/ /opt/mssql-tools/
COPY --from=mssql /usr/lib/libmsodbcsql-13.so /usr/lib/libmsodbcsql-13.so

# 复制oracle的SDK
COPY ./ori-sdk /tmp/oracle-sdk

RUN set -xe \
    # mssql 扩展所需库
    && apk add --no-cache --virtual .persistent-deps \
        freetds \
        unixodbc \
        # oracle 扩展所需库
        libaio-dev libnsl-dev libc6-compat \
    # 安装mssql扩展
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        unixodbc-dev \
        freetds-dev \
    && docker-php-source extract \
    && docker-php-ext-install pdo_dblib \
    && pecl install \
        sqlsrv \
        pdo_sqlsrv \
    && docker-php-ext-enable --ini-name 30-sqlsrv.ini sqlsrv \
    && docker-php-ext-enable --ini-name 35-pdo_sqlsrv.ini pdo_sqlsrv \
    # 安装oracle扩展
    unzip /tmp/oracle-sdk/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /usr/local/ && \
    unzip /tmp/oracle-sdk/instantclient-sdk-linux.x64-12.1.0.2.0.zip -d /usr/local/ && \
    unzip /tmp/oracle-sdk/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip -d /usr/local/ && \
    ln -s /usr/local/instantclient_12_1 /usr/local/instantclient && \
    ln -s /usr/local/instantclient/libclntsh.so.* /usr/local/instantclient/libclntsh.so && \
    ln -s /usr/local/libclntshcore.so.* /usr/local/instantclient/libclntshcore.so && \
    ln -s /usr/local/instantclient/libocci.so.* /usr/local/instantclient/libocci.so && \
    ln -s /usr/local/instantclient/sqlplus /usr/bin/sqlplus && \
    ln -s /usr/local/instantclient/lib* /usr/lib && \
    ln -s /usr/lib/libnsl.so.2 /usr/lib/libnsl.so.1 && \
    docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/usr/local/instantclient,12.1 && \
    docker-php-ext-install pdo_oci