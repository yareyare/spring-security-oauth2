-- 参考官方

create schema if not exists msa_jdbc collate utf8mb4_unicode_ci;

create table if not exists clientdetails
(
	appId varchar(128) not null
		primary key,
	resourceIds varchar(256) null,
	appSecret varchar(256) null,
	scope varchar(256) null,
	grantTypes varchar(256) null,
	redirectUrl varchar(256) null,
	authorities varchar(256) null,
	access_token_validity int null,
	refresh_token_validity int null,
	additionalInformation varchar(4096) null,
	autoApproveScopes varchar(256) null
)
charset=utf8;

create table if not exists oauth_access_token
(
	token_id varchar(256) null,
	token blob null,
	authentication_id varchar(128) not null
		primary key,
	user_name varchar(256) null,
	client_id varchar(256) null,
	authentication blob null,
	refresh_token varchar(256) null
)
charset=utf8;

create table if not exists oauth_approvals
(
	userId varchar(256) null,
	clientId varchar(256) null,
	scope varchar(256) null,
	status varchar(10) null,
	expiresAt timestamp null,
	lastModifiedAt timestamp null
)
charset=utf8;

create table if not exists oauth_client_details
(
	client_id varchar(128) not null
		primary key,
	resource_ids varchar(256) null,
	client_secret varchar(256) null,
	scope varchar(256) null,
	authorized_grant_types varchar(256) null,
	web_server_redirect_uri varchar(256) null,
	authorities varchar(256) null,
	access_token_validity int null,
	refresh_token_validity int null,
	additional_information varchar(4096) null,
	autoapprove varchar(256) null
)
charset=utf8;

create table if not exists oauth_client_token
(
	token_id varchar(256) null,
	token blob null,
	authentication_id varchar(128) not null
		primary key,
	user_name varchar(256) null,
	client_id varchar(256) null
)
charset=utf8;

create table if not exists oauth_code
(
	code varchar(256) null,
	authentication blob null
)
charset=utf8;

create table if not exists oauth_refresh_token
(
	token_id varchar(256) null,
	token blob null,
	authentication blob null
)
charset=utf8;

create table if not exists tb_permission
(
	id bigint auto_increment
		primary key,
	parent_id bigint null comment '父权限',
	name varchar(64) not null comment '权限名称',
	enname varchar(64) not null comment '权限英文名称',
	url varchar(255) not null comment '授权路径',
	description varchar(200) null comment '备注',
	created datetime not null,
	updated datetime not null
)
comment '权限表' charset=utf8;

create table if not exists tb_role
(
	id bigint auto_increment
		primary key,
	parent_id bigint null comment '父角色',
	name varchar(64) not null comment '角色名称',
	enname varchar(64) not null comment '角色英文名称',
	description varchar(200) null comment '备注',
	created datetime not null,
	updated datetime not null
)
comment '角色表' charset=utf8;

create table if not exists tb_role_permission
(
	id bigint auto_increment
		primary key,
	role_id bigint not null comment '角色 ID',
	permission_id bigint not null comment '权限 ID'
)
comment '角色权限表' charset=utf8;

create table if not exists tb_user
(
	id bigint auto_increment
		primary key,
	username varchar(50) not null comment '用户名',
	password varchar(64) not null comment '密码，加密存储',
	phone varchar(20) null comment '注册手机号',
	email varchar(50) null comment '注册邮箱',
	created datetime not null,
	updated datetime not null,
	constraint email
		unique (email),
	constraint phone
		unique (phone),
	constraint username
		unique (username)
)
comment '用户表' charset=utf8;

create table if not exists tb_user_role
(
	id bigint auto_increment
		primary key,
	user_id bigint not null comment '用户 ID',
	role_id bigint not null comment '角色 ID'
)
comment '用户角色表' charset=utf8;

