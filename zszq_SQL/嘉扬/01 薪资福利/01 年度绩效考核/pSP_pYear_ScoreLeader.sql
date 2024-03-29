USE [zszq]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  proc [dbo].[pSP_pYear_ScoreLeader]
    @id int,
    @URID int,
    @RetVal int=0 output
as
/*
-- Create By wuliang E004205
-- 年度考核评分开启
*/
begin

    -- 申明
    declare @pYear_ID varchar(20)

    -- @pYear_ID(年度考核ID)
    select @pYear_ID=id from pYear_Process where id=@id

    -- 年度考核未开启，无法开启考核评分！
    if exists (select 1 from pYear_Process where id=@id and isnull(Submit,0)=0)
    Begin
        Set @RetVal=1001100
        Return @RetVal
    End

    -- 年度考核评分已开启，无需重新开启！
    if exists (select 1 from pYear_Score where Score_Status=9 and isnull(Initialized,0)=1)
    Begin
        Set @RetVal=1001110
        Return @RetVal
    End

    -- 年度考核已封帐，无法开启考核评分！
    if exists (select 1 from pYear_Process where id=@id and ISNULL(Closed,0)=1)
    Begin
        Set @RetVal=1001120
        Return @RetVal
    end


    BEGIN TRANSACTION

    -- 添加员工打分排名表字段
    -- SCORE_STATUS初始值为大于等于2，且不等于9
    insert into pYear_Score (EID,pYear_ID,Score_Status,Score_Type1,Score_Type2,Score_EID,Score_DepID,Weight1,Weight2,Weight3,Modulus)
    select a.EID,@id,a.Score_Status,a.Score_Type1,a.Score_Type2,a.Score_EID,a.Score_DepID,a.Weight1,a.Weight2,a.Weight3,a.Modulus
    from pVW_pYear_ScoreType a,eEmployee b
    where a.EID=b.EID and b.Status in (1,2,3) and a.Score_Status>=2 and a.Score_Status<>9
    and a.EID not in (select EID from pYear_Score where Score_Status<>9 and Score_Status>=2)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -------- pYear_Score --------
    -- 更新总部的Initialized
    ---- 总部部门负责人
    ---- Score_Status=2,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=1 and a.Score_Status in (2,3,4)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 总部部门副职
    ---- Score_Status=2,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=2 and a.Score_Status=2
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 更新子公司的Initialized
    ---- 子公司合规总监
    ---- Score_Status=2,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=26 and a.Score_Status=2
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 子公司部门行政负责人(非合规:DepID<>666)
    ---- Score_Status=3,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=10 and a.Score_Status=3 and a.Score_DepID<>666
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 子公司部门行政负责人(合规:DepID=666)
    ---- Score_Status=2,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=10 and a.Score_Status=2 and a.Score_DepID=666
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 更新分公司/营业部的Initialized
    ---- 分公司/一级营业部负责人
    ---- Score_Status=2,Initialized=1
    update a
    set Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where Score_Type1 in (5,24) and Score_Status=2
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- Score_Status=3,Initialized=1
    update a
    set Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where Score_Type1 in (5,24) and Score_Status=3
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 分公司副职、一级营业部副职、二级营业部经理室成员
    ---- Score_Status=2,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1 in (25,6,7) and a.Score_Status=2
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 更新普通员工的Initialized
    ---- 更新总部普通员工、子公司普通员工、分公司普通员工、一级营业部普通员工的Initialized为1
    ---- Score_Status=9
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1 in (4,11,29,12) and a.Score_Status=9
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 更新二级营业部普通员工(分公司/一级营业部兼职二级营业部负责人考核)的Initialized为1
    ---- Score_Status=9
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=13 and a.Score_Status=9 and dbo.eFN_getdepdirector(a.Score_DepID)=dbo.eFN_getdepdirector2(a.Score_DepID)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 更新二级营业部普通员工(二级营业部负责人考核)的Initialized为1
    ---- Score_Status=2
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=13 and a.Score_Status=2 and dbo.eFN_getdepdirector(a.Score_DepID)<>dbo.eFN_getdepdirector2(a.Score_DepID)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 更新营业部合规风控专员的Initialized
    -- Score_Status=3,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=14 and a.Score_Status=3
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 更新营业部财务的Initialized
    ---- 营业部区域财务经理
    ---- Score_Status=2,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type1=17 and a.Score_Status=2
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 营业部综合会计(有对应区域财务经理)
    ---- Score_Status=2,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a,oDepartment c
    where a.Score_Type1=19 and a.Score_Status=2 and a.Score_DepID=c.DepID AND c.CWEID is not NULL
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- 营业部综合会计(无对应区域财务经理)
    ---- Score_Status=9,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a,oDepartment c
    where a.Score_Type1=19 and a.Score_Status=9 and a.Score_DepID=c.DepID AND c.CWEID is NULL
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 更新兼职合规的Initialized
    ---- 营业部合规联系人、总部兼职合规专员
    ---- Score_Status=7,Initialized=1
    update a
    set a.Initialized=1,a.InitializedBy=@URID,a.Initializedtime=GETDATE()
    from pYear_Score a
    where a.Score_Type2 in (15,16) and a.Score_Status=7
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM


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