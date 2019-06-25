model-1 【基于内存存储令牌】

快速理解 oAuth2 认证服务器中 "认证"、"授权"、"访问令牌” 的基本概念
参考：https://www.funtl.com/zh/spring-security-oauth2/%E5%9F%BA%E4%BA%8E%E5%86%85%E5%AD%98%E5%AD%98%E5%82%A8%E4%BB%A4%E7%89%8C.html#%E6%A6%82%E8%BF%B0

# 流程：
1. 客户端请求认证服务获取授权码，请求地址：http://localhost:8080/oauth/authorize?client_id=client&response_type=code
2. 认证通过回调注册的url，携带参数 code（即：认证服务器派发的授权码）
3. 客户端请求认证服务器获取访问令牌
    - 请求地址：http://youClientId:youSecret@localhost:8080/auth/token
    - 参数类型：application/x-www-form-urlencoded
    - 参数：
        - grant-type: authorization_code
        - code: youCode


# 配置认证服务器
. 配置客户端信息：ClientDetailsServiceConfigurer
    - inMemory：内存配置
    - withClient：客户端标识
    - secret：客户端安全码
    - authorizedGrantTypes：客户端授权类型
    - scopes：客户端授权范围
    - redirectUris：注册回调地址
. 配置 Web 安全
. 通过 GET 请求访问认证服务器获取授权码
    端点：/oauth/authorize
. 通过 POST 请求利用授权码访问认证服务器获取令牌
    端点：/oauth/token

附：默认的端点 URL
    /oauth/authorize：授权端点
    /oauth/token：令牌端点
    /oauth/confirm_access：用户确认授权提交端点
    /oauth/error：授权服务错误信息端点
    /oauth/check_token：用于资源服务访问的令牌解析端点
    /oauth/token_key：提供公有密匙的端点，如果你使用 JWT 令牌的话

# 配置认证服务器
创建一个类继承 AuthorizationServerConfigurerAdapter 并添加相关注解：
    @Configuration
    @EnableAuthorizationServer

# 服务器安全配置
创建一个类继承 WebSecurityConfigurerAdapter 并添加相关注解：
    @Configuration
    @EnableWebSecurity
    @EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true, jsr250Enabled = true)：全局方法拦截

application.yml 配置

# 访问获取授权码
    打开浏览器，输入地址：http://localhost:8080/oauth/authorize?client_id=client&response_type=code
    第一次访问会跳转到登录页面：输入application.yml 文件里的用户名和密码。sign in 后进入Oauth approval页面，选中approval，
    点击authorize按钮，页面回跳转到AuthorizationServerConfiguration.java 里配置的redirectUris页面上
    浏览器地址上还会包含一个授权码（code=J9ECnU），浏览器地址栏会显示如下地址：https://github.com/yareyare?code=J9ECnU
    有了这个授权码就可以获取访问令牌了

#通过授权码向服务器申请令牌
    通过 CURL 或是 Postman 请求：curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'grant_type=authorization_code&code=J9ECnU' "http://client:secret@localhost:8080/oauth/token"



# 附录：
Exception：There is no PasswordEncoder mapped for the id "null"
解决方案：Spring Security 5.0 之前版本的 PasswordEncoder 接口默认实现为 NoOpPasswordEncoder 此时是可以使用明文密码的，在 5.0 之后默认实现类改为 DelegatingPasswordEncoder 此时密码必须以加密形式存储

application.yml
删除：spring.security 相关配置，修改为：
spring:
  application:
    name: oauth2-server
server:
  port: 8080


WebSecurityConfiguration

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


AuthorizationServerConfiguration
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.oauth2.config.annotation.configurers.ClientDetailsServiceConfigurer;
import org.springframework.security.oauth2.config.annotation.web.configuration.AuthorizationServerConfigurerAdapter;
import org.springframework.security.oauth2.config.annotation.web.configuration.EnableAuthorizationServer;

@Configuration
@EnableAuthorizationServer
public class AuthorizationServerConfiguration extends AuthorizationServerConfigurerAdapter {

    // 注入 WebSecurityConfiguration 中配置的 BCryptPasswordEncoder
    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
        clients
                .inMemory()
                .withClient("client")
                // 还需要为 secret 加密
                .secret(passwordEncoder.encode("secret"))
                .authorizedGrantTypes("authorization_code")
                .scopes("app")
                .redirectUris("http://www.funtl.com");

    }
}

通过CURL 请求：curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'grant_type=authorization_code&code=J9ECnU' "http://client:secret@localhost:8080/oauth/token"