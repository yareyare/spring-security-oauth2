package com.ivy.security.mapper;

import com.ivy.security.domain.TbUser;
import tk.mybatis.mapper.common.Mapper;

public interface TbUserMapper extends Mapper<TbUser> {

    TbUser selectByUserName(String username);
}