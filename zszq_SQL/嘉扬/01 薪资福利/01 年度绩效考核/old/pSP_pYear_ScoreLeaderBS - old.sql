USE [zszq]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[pSP_pYear_ScoreLeaderBS]
    @Score_Status int,    -- leftid实际返回内容为score_status
    @Score_Type int,
    @EID int,
    @RetVal int=0 OutPut
as
/*
-- Create By wuliang E004205
-- 年度考核评分递交
*/
Begin


    -------- pYear_Score --------

    -- 考核评分为空，无法递交员工考核评分！
    ---- 非综合会计(非集中)
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Type not in (20) AND ScoreTotal is NULL)
    Begin
        Set @RetVal=1002130
        Return @RetVal
    End
    ---- 综合会计(非集中)
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Type in (20) AND ScoreTotal is NULL)
    Begin
        Set @RetVal=1002130
        Return @RetVal
    End

    -------- 总部部门负责人、总部副职、子公司部门负责人 考核评分判断 --------
    -- 考核评分超出上限，无法递交员工考核评分！
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Status in (2,3) AND @Score_Type in (1,2,10)
    and (ISNULL(Score1,0) not between 0 and 100 or ISNULL(Score2,0) not between 0 and 100))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End

    -------- 分公司负责人/一级营业部负责人 考核评分判断 --------
    -- 考核评分超出上限，无法递交员工考核评分！
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Status in (2,3,4,5) AND @Score_Type in (245)
    and (ISNULL(Score1,0) not between 0 and 100))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End

    -------- 分公司副职/一级营业部副职/二级营业部经理室 考核评分判断 --------
    -- 考核评分超出上限，无法递交员工考核评分！
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Status in (2,3) AND @Score_Type in (2567)
    and (ISNULL(Score1,0) not between 0 and 100 or ISNULL(Score2,0) not between 0 and 100 or ISNULL(Score3,0) not between 0 and 100))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End

    -------- 总部普通员工、子公司普通员工、分公司/一级营业部及二级营业部普通员工 评分判断 --------
    -- 考核评分超出上限，无法递交员工考核评分！
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Status in (2,3) AND @Score_Type in (4,11,291213,13)
    and (ISNULL(Score1,0) not between 0 and 50 or ISNULL(Score2,0) not between 0 and 5
    or ISNULL(Score3,0) not between 0 and 5 or ISNULL(Score4,0) not between 0 and 10
    or ISNULL(Score5,0) not between 0 and 5 or ISNULL(Score6,0) not between 0 and 5
    or ISNULL(Score7,0) not between 0 and 10 or ISNULL(Score8,0) not between 0 and 10))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End

    -------- 区域财务经理、营业部合规风控专员 评分判断 --------
    -- 考核评分超出上限，无法递交员工考核评分！
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Status in (1,2,3) AND @Score_Type in (17,14)
    and (ISNULL(Score1,0) not between 0 and 100 or ISNULL(Score2,0) not between 0 and 100))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End

    -------- 综合会计（集中）、综合会计（非集中） 评分判断 --------
    -- 考核评分超出上限，无法递交员工考核评分！
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Status in (1,2) AND @Score_Type in (19,20,1920)
    and (ISNULL(Score1,0) not between 0 and 50 or ISNULL(Score2,0) not between 0 and 5
    or ISNULL(Score3,0) not between 0 and 5 or ISNULL(Score4,0) not between 0 and 10
    or ISNULL(Score5,0) not between 0 and 5 or ISNULL(Score6,0) not between 0 and 5
    or ISNULL(Score7,0) not between 0 and 10 or ISNULL(Score8,0) not between 0 and 10))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End

    -------- 营业部合规联系人、总部兼职合规专员 评分判断 --------
    -- 考核评分超出上限，无法递交员工考核评分！
    IF Exists(select 1 from pYear_Score where Score_EID=@EID
    AND @Score_Status in (7) AND @Score_Type in (15,16)
    and (ISNULL(Score1,0) not between 0 and 100))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End


    Begin TRANSACTION

    -------- pYear_Score --------
    -- 更新pYear_Score，更新当前阶段递交状态
    update a
    set a.Submit=1,a.SubmitBy=(select ID from SkySecUser where EID=@EID),a.SubmitTime=GETDATE()
    from pYear_Score a
    where Score_EID=@EID and Score_Status=@Score_Status 
    and (Score_Type1=@Score_Type or Score_Type2=@Score_Type) and @Score_Type not in (245,2567,291213,1920)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 245: 分公司负责人/一级营业部负责人
    update a
    set a.Submit=1,a.SubmitBy=(select ID from SkySecUser where EID=@EID),a.SubmitTime=GETDATE()
    from pYear_Score a
    where Score_EID=@EID and Score_Status=@Score_Status 
    and Score_Type1 in (24,5) and @Score_Type in (245)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 2567: 分公司副职/一级营业部副职/二级营业部经理室
    update a
    set a.Submit=1,a.SubmitBy=(select ID from SkySecUser where EID=@EID),a.SubmitTime=GETDATE()
    from pYear_Score a
    where Score_EID=@EID and Score_Status=@Score_Status 
    and Score_Type1 in (25,6,7) and @Score_Type in (2567)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 291213: 分公司/一级营业部及二级营业部普通员工
    update a
    set a.Submit=1,a.SubmitBy=(select ID from SkySecUser where EID=@EID),a.SubmitTime=GETDATE()
    from pYear_Score a
    where Score_EID=@EID and Score_Status=@Score_Status 
    and Score_Type1 in (29,12,13) and @Score_Type in (291213)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 1920: 综合会计（集中）、综合会计（非集中）
    update a
    set a.Submit=1,a.SubmitBy=(select ID from SkySecUser where EID=@EID),a.SubmitTime=GETDATE()
    from pYear_Score a
    where Score_EID=@EID and Score_Status=@Score_Status 
    and Score_Type1 in (19,20) and @Score_Type in (1920)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    

    -- 更新pYear_Score，更新下一阶段初始化状态
    update a
    set a.Initialized=1,a.InitializedBy=(select ID from SkySecUser where EID=@EID),a.InitializedTime=GETDATE()
    from pYear_Score a
    where a.Score_Status=(select MIN(Score_Status) from pYear_Score 
    where (Score_Type1=@Score_Type or Score_Type2=@Score_Type) and @Score_Type not in (245,2567,291213,1920) and ISNULL(Initialized,0)=0)
    and a.EID in (select EID from pYear_Score where (Score_Type1=@Score_Type or Score_Type2=@Score_Type) and @Score_Type not in (245,2567,291213,1920) 
    and a.Score_EID=@EID and ISNULL(a.Initialized,0)=1)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 245: 分公司负责人/一级营业部负责人
    update a
    set a.Initialized=1,a.InitializedBy=(select ID from SkySecUser where EID=@EID),a.InitializedTime=GETDATE()
    from pYear_Score a
    where a.Score_Status=(select MIN(Score_Status) from pYear_Score 
    where Score_Type1 in (24,5) and @Score_Type in (245) and ISNULL(Initialized,0)=0)
    and a.EID in (select EID from pYear_Score where (Score_Type1=@Score_Type or Score_Type2=@Score_Type) and @Score_Type in (245) 
    and a.Score_EID=@EID and ISNULL(a.Initialized,0)=1)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 2567: 分公司副职/一级营业部副职/二级营业部经理室
    update a
    set a.Initialized=1,a.InitializedBy=(select ID from SkySecUser where EID=@EID),a.InitializedTime=GETDATE()
    from pYear_Score a
    where a.Score_Status=(select MIN(Score_Status) from pYear_Score 
    where Score_Type1 in (25,6,7) and @Score_Type in (2567) and ISNULL(Initialized,0)=0)
    and a.EID in (select EID from pYear_Score where (Score_Type1=@Score_Type or Score_Type2=@Score_Type) and @Score_Type in (2567) 
    and a.Score_EID=@EID and ISNULL(a.Initialized,0)=1)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 291213: 分公司/一级营业部及二级营业部普通员工
    update a
    set a.Initialized=1,a.InitializedBy=(select ID from SkySecUser where EID=@EID),a.InitializedTime=GETDATE()
    from pYear_Score a
    where a.Score_Status=(select MIN(Score_Status) from pYear_Score 
    where Score_Type1 in (29,12,13) and @Score_Type in (291213) and ISNULL(Initialized,0)=0)
    and a.EID in (select EID from pYear_Score where (Score_Type1=@Score_Type or Score_Type2=@Score_Type) and @Score_Type in (291213) 
    and a.Score_EID=@EID and ISNULL(a.Initialized,0)=1)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -- 1920: 综合会计（集中）、综合会计（非集中）
    update a
    set a.Initialized=1,a.InitializedBy=(select ID from SkySecUser where EID=@EID),a.InitializedTime=GETDATE()
    from pYear_Score a
    where a.Score_Status=(select MIN(Score_Status) from pYear_Score 
    where Score_Type1 in (19,20) and @Score_Type in (1920) and ISNULL(Initialized,0)=0)
    and a.EID in (select EID from pYear_Score where (Score_Type1=@Score_Type or Score_Type2=@Score_Type) and @Score_Type in (1920) 
    and a.Score_EID=@EID and ISNULL(a.Initialized,0)=1)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM


    -- 更新最终评分及排名统计分数
    -- 总部部门负责人、总部部门副职、子公司部门行政负责人、分公司副职、一级营业部副职、二级营业部经理室成员
    ---- Score_Status=2时Score11
    update a
    set a.Score11=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2 
    and b.Score_Type1 in (1,2,10,25,6,7) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 分公司负责人、一级营业部负责人
    ---- Score_Status=2时Score11
    update a
    set a.Score11=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1 in (24,5) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=3时Score12
    update a
    set a.Score12=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=3
    and b.Score_Type1 in (24,5) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=4时Score13
    update a
    set a.Score13=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=4
    and b.Score_Type1 in (24,5) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 二级营业部普通员工
    ---- Score_Status=2时Score11
    update a
    set a.Score11=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1 in (13) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 营业部合规风控专员、营业部区域财务经理
    ---- Score_Status=1时Score11
    update a
    set a.Score11=(select AVG(ScoreTotal) from pYear_Score 
    where EID=a.EID and Score_Status=1 and Score_Type1 in (14,17) and Score_EID=@EID and ISNULL(Submit,0)=1)
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=2时Score12
    update a
    set a.Score12=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1 in (14,17) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 综合会计（集中）
    ---- Score_Status=1时Score11
    update a
    set a.Score11=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=1
    and b.Score_Type1 in (19) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 综合会计（非集中）
    ---- Score_Status=1时Score11
    update a
    set a.Score11=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=1
    and b.Score_Type1 in (20) and b.Score_EID=@EID and ISNULL(b.Submit,0)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 总部兼职合规专员、营业部合规联系人
    ---- Score_Status=7时Score14
    update a
    set a.Score14=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=7
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM


    -- 正常处理流程
    COMMIT TRANSACTION
    Set @RetVal=0
    Return @RetVal

    -- 异常处理流程
    ErrM:
    ROLLBACK TRANSACTION
    If ISNULL(@RetVal,0)=0
        Set @RetVal=-1
        Return @RetVal
End