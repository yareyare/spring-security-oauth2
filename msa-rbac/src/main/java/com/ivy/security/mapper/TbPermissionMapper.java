package com.ivy.security.mapper;

import com.ivy.security.domain.TbPermission;
import tk.mybatis.mapper.common.Mapper;

import java.util.List;

public interface TbPermissionMapper extends Mapper<TbPermission> {

    List<TbPermission> selectByUserId(Long userId);

}