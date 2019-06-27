model-3 【基于RBAC的自定义认证】

--------------------------------------------------------------------------------
进入地址：http://localhost:8080/oauth/authorize?client_id=msa&response_type=code
--------------------------------------------------------------------------------

视频：
https://www.bilibili.com/video/av48590637/?p=13
https://www.bilibili.com/video/av48590637/?p=14
文档
https://www.funtl.com/zh/spring-security-oauth2/%E5%9F%BA%E4%BA%8E-RBAC-%E7%9A%84%E8%87%AA%E5%AE%9A%E4%B9%89%E8%AE%A4%E8%AF%81.html#%E6%9C%AC%E8%8A%82%E8%A7%86%E9%A2%91

基于角色的访问控制
RBAC 基于角色
    支持著名的安全三原则：
    最小权限原则
    责任分离原则
    数据抽象原则
ACL  访问控制列表
ABAC 基于属性
PBAC 基于策略
权限控制模型

是什么：权限控制模型
为什么：
    who：资源所有者？
    what：能访问哪些资源？
    how：具体怎么访问？
怎么用：
    who：user
    what：
        静态资源：功能操作，数据列
        动态资源：数据，文章，相册，笔记
        post：
            新增文章
            删除文章
            查看相片
            删除相片
    how：CRUD
user：
role：
permission
user_role
role_permission

1. 概述
    在实际开发中，我们的用户信息都是存在数据库里的，本章节基于 RBAC 模型 将用户的认证信息与数据库对接，实现真正的用户认证与授权

2. 操作流程
    基于JDBC存储令牌的代码开发
    初始化 RBAC 相关表
    在数据库中配置“用户”、“角色”、“权限”相关信息
    数据库操作使用 tk.mybatis 框架，故需要增加相关依赖
    配置 Web 安全
        配置使用自定义认证与授权
    通过 GET 请求访问认证服务器获取授权码
        端点：/oauth/authorize
    通过 POST 请求利用授权码访问认证服务器获取令牌
        端点：/oauth/token

3. 附：默认的端点 URL

   /oauth/authorize：授权端点
   /oauth/token：令牌端点
   /oauth/confirm_access：用户确认授权提交端点
   /oauth/error：授权服务错误信息端点
   /oauth/check_token：用于资源服务访问的令牌解析端点
   /oauth/token_key：提供公有密匙的端点，如果你使用 JWT 令牌的话

4. 初始化 RBAC 相关表

    CREATE TABLE `tb_permission` (
      `id` bigint(20) NOT NULL AUTO_INCREMENT,
      `parent_id` bigint(20) DEFAULT NULL COMMENT '父权限',
      `name` varchar(64) NOT NULL COMMENT '权限名称',
      `enname` varchar(64) NOT NULL COMMENT '权限英文名称',
      `url` varchar(255) NOT NULL COMMENT '授权路径',
      `description` varchar(200) DEFAULT NULL COMMENT '备注',
      `created` datetime NOT NULL,
      `updated` datetime NOT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8 COMMENT='权限表';
    insert  into `tb_permission`(`id`,`parent_id`,`name`,`enname`,`url`,`description`,`created`,`updated`) values
    (37,0,'系统管理','System','/',NULL,'2019-04-04 23:22:54','2019-04-04 23:22:56'),
    (38,37,'用户管理','SystemUser','/users/',NULL,'2019-04-04 23:25:31','2019-04-04 23:25:33'),
    (39,38,'查看用户','SystemUserView','',NULL,'2019-04-04 15:30:30','2019-04-04 15:30:43'),
    (40,38,'新增用户','SystemUserInsert','',NULL,'2019-04-04 15:30:31','2019-04-04 15:30:44'),
    (41,38,'编辑用户','SystemUserUpdate','',NULL,'2019-04-04 15:30:32','2019-04-04 15:30:45'),
    (42,38,'删除用户','SystemUserDelete','',NULL,'2019-04-04 15:30:48','2019-04-04 15:30:45');

    CREATE TABLE `tb_role` (
      `id` bigint(20) NOT NULL AUTO_INCREMENT,
      `parent_id` bigint(20) DEFAULT NULL COMMENT '父角色',
      `name` varchar(64) NOT NULL COMMENT '角色名称',
      `enname` varchar(64) NOT NULL COMMENT '角色英文名称',
      `description` varchar(200) DEFAULT NULL COMMENT '备注',
      `created` datetime NOT NULL,
      `updated` datetime NOT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COMMENT='角色表';
    insert  into `tb_role`(`id`,`parent_id`,`name`,`enname`,`description`,`created`,`updated`) values
    (37,0,'超级管理员','admin',NULL,'2019-04-04 23:22:03','2019-04-04 23:22:05');

    CREATE TABLE `tb_role_permission` (
      `id` bigint(20) NOT NULL AUTO_INCREMENT,
      `role_id` bigint(20) NOT NULL COMMENT '角色 ID',
      `permission_id` bigint(20) NOT NULL COMMENT '权限 ID',
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8 COMMENT='角色权限表';
    insert  into `tb_role_permission`(`id`,`role_id`,`permission_id`) values
    (37,37,37),
    (38,37,38),
    (39,37,39),
    (40,37,40),
    (41,37,41),
    (42,37,42);

    CREATE TABLE `tb_user` (
      `id` bigint(20) NOT NULL AUTO_INCREMENT,
      `username` varchar(50) NOT NULL COMMENT '用户名',
      `password` varchar(64) NOT NULL COMMENT '密码，加密存储',
      `phone` varchar(20) DEFAULT NULL COMMENT '注册手机号',
      `email` varchar(50) DEFAULT NULL COMMENT '注册邮箱',
      `created` datetime NOT NULL,
      `updated` datetime NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `username` (`username`) USING BTREE,
      UNIQUE KEY `phone` (`phone`) USING BTREE,
      UNIQUE KEY `email` (`email`) USING BTREE
    ) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COMMENT='用户表';
    insert  into `tb_user`(`id`,`username`,`password`,`phone`,`email`,`created`,`updated`) values
    (37,'admin','$2a$10$9ZhDOBp.sRKat4l14ygu/.LscxrMUcDAfeVOEPiYwbcRkoB09gCmi','15888888888','lee.lusifer@gmail.com','2019-04-04 23:21:27','2019-04-04 23:21:29');

    CREATE TABLE `tb_user_role` (
      `id` bigint(20) NOT NULL AUTO_INCREMENT,
      `user_id` bigint(20) NOT NULL COMMENT '用户 ID',
      `role_id` bigint(20) NOT NULL COMMENT '角色 ID',
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8 COMMENT='用户角色表';
    insert  into `tb_user_role`(`id`,`user_id`,`role_id`) values
    (37,37,37);

5. 由于使用了 BCryptPasswordEncoder 的加密方式，故用户密码需要加密，代码如下：
   System.out.println(new BCryptPasswordEncoder().encode("123456"));

6. POM
    数据库操作采用 tk.mybatis 框架，需增加相关依赖

    <dependency>
        <groupId>tk.mybatis</groupId>
        <artifactId>mapper-spring-boot-starter</artifactId>
    </dependency>

7. 关键步骤
    由于本次增加了 MyBatis 相关操作，代码增加较多，可以参考本项目源码，下面仅列出关键步骤及代码

8. 获取用户信息
    目的是为了实现自定义认证授权时可以通过数据库查询用户信息，Spring Security oAuth2 要求使用 username 的方式查询，提供相关用户信息后，认证工作由框架自行完成

9. 将本地用户config到security

import com.ivy.security.domain.TbPermission;
import com.ivy.security.domain.TbUser;
import com.ivy.security.service.TbPermissionService;
import com.ivy.security.service.TbUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * @author ivy on 2019-06-26.
 */
@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    @Autowired
    private TbUserService tbUserService;

    @Autowired
    private TbPermissionService tbPermissionService;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        TbUser tbUser = tbUserService.getByUsername(username);
        List<GrantedAuthority> grantedAuthorities = new ArrayList<>();
        if (tbUser != null) {
            // 获取用户授权
            List<TbPermission> tbPermissions = tbPermissionService.selectByUserId(tbUser.getId());

            // 声明用户授权
            tbPermissions.forEach(tbPermission -> {
                if (tbPermission != null && tbPermission.getEnname() != null) {
                    GrantedAuthority grantedAuthority = new SimpleGrantedAuthority(tbPermission.getEnname());
                    grantedAuthorities.add(grantedAuthority);
                }
            });
        }
        return new User(tbUser.getUsername(), tbUser.getPassword(), grantedAuthorities);
    }
}

10.

11. 通过授权码向服务器申请令牌
    通过 CURL 或是 Postman 请求：curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'grant_type=authorization_code&code=J9ECnU' "http://client:secret@localhost:8080/oauth/token"

12. 通过授权码获取token
    curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'grant_type=authorization_code&code=1JuO6V' "http://client:secret@localhost:8080/oauth/token"