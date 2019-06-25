model-2 【基于JDBC存储令牌】

--------------------------------------------------------------------------------
进入地址：http://localhost:8080/oauth/authorize?client_id=client&response_type=code
--------------------------------------------------------------------------------

1.建表
  sql 见schema.sql

2.在数据库中配置客户端
在表 oauth_client_details 中增加一条客户端配置记录，需要设置的字段如下：
    client_id：客户端标识
    client_secret：客户端安全码，此处不能是明文，需要加密
    scope：客户端授权范围
    authorized_grant_types：客户端授权类型
    web_server_redirect_uri：服务器回调地址


使用 BCryptPasswordEncoder 为客户端安全码加密，代码如下：
    System.out.println(new BCryptPasswordEncoder().encode("secret"));

数据库配置客户端:
    INSERT INTO msa_jdbc.oauth_client_details (client_id, resource_ids, client_secret, scope, authorized_grant_types, web_server_redirect_uri, authorities, access_token_validity, refresh_token_validity, additional_information, autoapprove) VALUES ('msa', null, '$2a$10$oECnq4znkfwab7qRAL92re3k67zLCIHme4p.ISVNG0AhmNxBUbafy', 'password,refresh_token,authorization_code', 'authorization_code', 'https://github.com/yareyare', null, null, null, null, 'true');

3. POM 由于使用了 JDBC 存储，我们需要增加相关依赖，数据库连接池部分弃用 Druid 改为 HikariCP （号称全球最快连接池）
    <dependency>
        <groupId>com.zaxxer</groupId>
        <artifactId>HikariCP</artifactId>
        <version>${hikaricp.version}</version>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-jdbc</artifactId>
        <exclusions>
            <!-- 排除 tomcat-jdbc 以使用 HikariCP -->
            <exclusion>
                <groupId>org.apache.tomcat</groupId>
                <artifactId>tomcat-jdbc</artifactId>
            </exclusion>
        </exclusions>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>${mysql.version}</version>
    </dependency>

4. 配置认证服务器
    创建一个类继承 AuthorizationServerConfigurerAdapter 并添加相关注解
    @Configuration
    @EnableAuthorizationServer


    import org.springframework.boot.context.properties.ConfigurationProperties;
    import org.springframework.boot.jdbc.DataSourceBuilder;
    import org.springframework.context.annotation.Bean;
    import org.springframework.context.annotation.Configuration;
    import org.springframework.context.annotation.Primary;
    import org.springframework.security.oauth2.config.annotation.configurers.ClientDetailsServiceConfigurer;
    import org.springframework.security.oauth2.config.annotation.web.configuration.AuthorizationServerConfigurerAdapter;
    import org.springframework.security.oauth2.config.annotation.web.configuration.EnableAuthorizationServer;
    import org.springframework.security.oauth2.config.annotation.web.configurers.AuthorizationServerEndpointsConfigurer;
    import org.springframework.security.oauth2.provider.ClientDetailsService;
    import org.springframework.security.oauth2.provider.client.JdbcClientDetailsService;
    import org.springframework.security.oauth2.provider.token.TokenStore;
    import org.springframework.security.oauth2.provider.token.store.JdbcTokenStore;

    import javax.sql.DataSource;

    @Configuration
    @EnableAuthorizationServer
    public class AuthorizationServerConfiguration extends AuthorizationServerConfigurerAdapter {

        @Bean
        @Primary
        @ConfigurationProperties(prefix = "spring.datasource")
        public DataSource dataSource() {
            // 配置数据源（注意，我使用的是 HikariCP 连接池），以上注解是指定数据源，否则会有冲突
            return DataSourceBuilder.create().build();
        }

        @Bean
        public TokenStore tokenStore() {
            // 基于 JDBC 实现，令牌保存到数据
            return new JdbcTokenStore(dataSource());
        }

        @Bean
        public ClientDetailsService jdbcClientDetails() {
            // 基于 JDBC 实现，需要事先在数据库配置客户端信息
            return new JdbcClientDetailsService(dataSource());
        }

        @Override
        public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
            // 设置令牌
            endpoints.tokenStore(tokenStore());
        }

        @Override
        public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
            // 读取客户端配置
            clients.withClientDetails(jdbcClientDetails());
        }
    }

5. 服务器安全配置
    创建一个类继承 WebSecurityConfigurerAdapter 并添加相关注解：
    @Configuration
    @EnableWebSecurity
    @EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true, jsr250Enabled = true)：全局方法拦截



    import org.springframework.context.annotation.Bean;
    import org.springframework.context.annotation.Configuration;
    import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
    import org.springframework.security.config.annotation.method.configuration.EnableGlobalMethodSecurity;
    import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
    import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
    import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

    @Configuration
    @EnableWebSecurity
    @EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true, jsr250Enabled = true)
    public class WebSecurityConfiguration extends WebSecurityConfigurerAdapter {

        @Bean
        public BCryptPasswordEncoder passwordEncoder() {
            // 设置默认的加密方式
            return new BCryptPasswordEncoder();
        }

        @Override
        protected void configure(AuthenticationManagerBuilder auth) throws Exception {

            auth.inMemoryAuthentication()
                    // 在内存中创建用户并为密码加密
                    .withUser("user").password(passwordEncoder().encode("123456")).roles("USER")
                    .and()
                    .withUser("admin").password(passwordEncoder().encode("123456")).roles("ADMIN");

        }
    }

6. application.yml
spring:
  application:
    name: oauth2-server
  datasource:
    type: com.zaxxer.hikari.HikariDataSource
    driver-class-name: com.mysql.cj.jdbc.Driver
    jdbc-url: jdbc:mysql://192.168.141.128:3307/oauth2?useUnicode=true&characterEncoding=utf-8&useSSL=false
    username: root
    password: 123456
    hikari:
      minimum-idle: 5
      idle-timeout: 600000
      maximum-pool-size: 10
      auto-commit: true
      pool-name: MyHikariCP
      max-lifetime: 1800000
      connection-timeout: 30000
      connection-test-query: SELECT 1

server:
  port: 8080

7. 访问获取授权码
    http://localhost:8080/oauth/authorize?client_id=client&response_type=code
    会跳到登录，登录成功后，认证，认证完成后会跳转到重定向地址上并且带着授权码

8. 通过授权码向服务器申请令牌
    curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'grant_type=authorization_code&code=1JuO6V' "http://client:secret@localhost:8080/oauth/token"
    响应结果中会有access_token，和超时时间
    {
        "access_token": "016d8d4a-dd6e-4493-b590-5f072923c413",
        "token_type": "bearer",
        "expires_in": 43199,
        "scope": "app"
    }
    操作成功后数据库 oauth_access_token 表中会增加一笔记录

