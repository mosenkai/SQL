USE [zszq]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- eSP_pYear_AppraiseStart 9,1
ALTER  proc [dbo].[eSP_pYear_AppraiseStart]
    @id int,
    @URID int,
    @RetVal int=0 output
as
/*
-- Create By wuliang E004205
-- 年度评优开启
*/
begin

    -- 上年度评优未关闭，无法再次开启
    if exists (select 1 from pYear_AppraiseProcess where id=@id-1 and isnull(Closed,0)=0)
    Begin
        Set @RetVal=1003010
        Return @RetVal
    End

    -- 年度评优已开启，无需重新开启！
    if exists (select 1 from pYear_AppraiseProcess where id=@id and isnull(Submit,0)=1)
    Begin
        Set @RetVal=1003020
        Return @RetVal
    End

    -- 年度评优已封帐，无法重新开启！
    if exists (select 1 from pYear_AppraiseProcess where id=@id and ISNULL(Closed,0)=1)
    Begin
        Set @RetVal=1003030
        Return @RetVal
    end


    BEGIN TRANSACTION

    -------- pYear_DepAppraise --------
    -- 公司领导(不含董事长、总裁、书记)
    insert into pYear_DepAppraise (pYear_ID,AppraiseEID)
    select distinct a.ID,b.EID
    from pYear_AppraiseProcess a,eEmployee b
    where a.ID=@id and b.DepID=349 AND b.EID not in (1022,5014,5587) AND b.Status not in (4,5)
    AND b.EID not in (select AppraiseEID from pYear_DepAppraise where pYear_ID=@id)
    -- 异常处理
    if @@ERROR<>0
    goto ErrM
    -- 总部部门(不包含公司领导、投资银行(695)下属部门、信息技术事业部下属部门(744,745)和财富管理事业部(811))
    insert into pYear_DepAppraise (pYear_ID,AppraiseEID)
    select distinct a.ID,b.Director
    from pYear_AppraiseProcess a,oDepartment b
    where a.ID=@id and ISNULL(b.isDisabled,0)=0 and b.xOrder<>9999999999999 and b.Director is not NULL
    and b.Director not in (select AppraiseEID from pYear_DepAppraise where pYear_ID=@id)
    and b.DepType=1 and b.DepGrade=1 and ISNULL(b.AdminID,0)<>695 and b.DepID not in (349,744,745,811) AND b.Director not in (1022,5014,5587)
    -- 异常处理
    if @@ERROR<>0
    goto ErrM
    -- 总部部门(投资银行(投资银行管理总部DepID:683))
    insert into pYear_DepAppraise (pYear_ID,AppraiseEID)
    select distinct a.ID,b.Director
    from pYear_AppraiseProcess a,oDepartment b
    where a.ID=@id and ISNULL(b.isDisabled,0)=0 and b.xOrder<>9999999999999 and b.Director is not NULL AND b.DepID=683
    and b.Director not in (select AppraiseEID from pYear_DepAppraise where pYear_ID=@id)
    -- 异常处理
    if @@ERROR<>0
    goto ErrM
    -- 子公司
    ---- 浙商资本DepID:392;浙商资管(运营管理总部DepID:795);浙商投资DepID:830
    insert into pYear_DepAppraise (pYear_ID,AppraiseEID)
    select distinct a.ID,b.Director
    from pYear_AppraiseProcess a,oDepartment b
    where a.ID=@id and ISNULL(b.isDisabled,0)=0 and b.xOrder<>9999999999999 and b.Director is not NULL
    and b.Director not in (select AppraiseEID from pYear_DepAppraise where pYear_ID=@id)
    and b.DepID in (392,795,830)
    -- 异常处理
    if @@ERROR<>0
    goto ErrM
    -- 一级分支机构
    insert into pYear_DepAppraise (pYear_ID,AppraiseEID)
    select distinct a.ID,b.Director
    from pYear_AppraiseProcess a,oDepartment b
    where a.ID=@id and ISNULL(b.isDisabled,0)=0 and b.xOrder<>9999999999999 and b.Director is not NULL
    and b.Director not in (select AppraiseEID from pYear_DepAppraise where pYear_ID=@id)
    and b.DepType in (2,3) and b.DepGrade=1
    -- 异常处理
    if @@ERROR<>0
    goto ErrM
    

    -------- pYear_AppraiseProcess --------
    -- 更新流程信息为开启
    update pYear_AppraiseProcess
    set Submit=1,Submitby=@URID,SubmitTime=GETDATE()
    where id=@id
    -- 异常处理
    if @@ERROR<>0
    goto ErrM


    -- 正常处理流程
    COMMIT TRANSACTION
    Set @Retval = 0
    Return @Retval

    -- 异常处理流程
    ErrM:
    ROLLBACK TRANSACTION
    Set @Retval = -1
    Return @Retval

end