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
    ---- @Score_Type：子公司负责人/子公司班子成员:1026;分公司/一级营业部负责人:245;分公司副职/一级营业部副职/二级营业部经理室:2567;分公司、一级营业部、二级营业部普通员工:291213
    IF Exists(select 1 from pYear_Score where Score_EID=@EID and Score_Status=@Score_Status 
    and ((Score_Type1=@Score_Type or Score_Type2=@Score_Type) or (Score_Type1 in (24,5) and @Score_Type=245)
    or (Score_Type1 in (25,6,7) and @Score_Type=2567) or (Score_Type1 in (29,12,13) and @Score_Type=291213)
    or (Score_Type1 in (10,26) and @Score_Type=1026))
    AND ScoreTotal is NULL)
    Begin
        Set @RetVal=1002130
        Return @RetVal
    End

    -- 考核评分超出上限，无法递交员工考核评分！
    ---- Score_Type1：总部普通员工:4;子公司普通员工:11;分公司普通员工:29;一级营业部普通员工:12;二级营业部普通员工:13;综合会计:19
    ---- @Score_Type：分公司、一级营业部、二级营业部普通员工:291213;综合会计:19
    IF Exists(select 1 from pYear_Score where Score_EID=@EID and Score_Status=@Score_Status 
    and (Score1 not between 0 and 50 or Score2 not between 0 and 5
    or Score3 not between 0 and 5 or Score4 not between 0 and 10
    or Score5 not between 0 and 5 or Score6 not between 0 and 5
    or Score7 not between 0 and 10 or Score8 not between 0 and 10)
    and ((@Score_Status in (2,9) AND Score_Type1 in (4,11,29,12,13) and @Score_Type in (4,11,291213,13))
    or (@Score_Status in (1,9) AND Score_Type1=19 and @Score_Type=19)))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End
    ---- 总部部门负责人、总部副职、子公司部门负责人、分公司负责人/一级营业部负责人、分公司副职/一级营业部副职/二级营业部经理室、
    ---- 区域财务经理、营业部合规风控专员、营业部合规联系人、总部兼职合规专员
    IF Exists(select 1 from pYear_Score where Score_EID=@EID and Score_Status=@Score_Status
    and (Score1 not between 0 and 100 or Score2 not between 0 and 100 or Score3 not between 0 and 100)
    AND ((@Score_Status in (2,3,9) AND Score_Type1 in (1,2,10) and @Score_Type in (1,2,10)) 
    or (@Score_Status in (2,3,4,5,9) AND Score_Type1 in (24,5) and @Score_Type=245)
    or (@Score_Status in (2,9) AND Score_Type1 in (25,6,7) and @Score_Type=2567)
    or (@Score_Status in (1,2,9) AND Score_Type1 in (17,14) and @Score_Type in (17,14))
    or (@Score_Status=7 AND Score_Type2 in (15,16) and @Score_Type in (15,16))))
    Begin
        Set @RetVal=1002120
        Return @RetVal
    End


    Begin TRANSACTION

    -------- pYear_Score --------
    -- 更新pYear_Score，更新当前阶段递交状态
    ---- Submit=1
    update a
    set a.Submit=1,a.SubmitBy=(select ID from SkySecUser where EID=@EID),a.SubmitTime=GETDATE()
    from pYear_Score a
    where Score_EID=@EID and Score_Status=@Score_Status 
    and ((Score_Type1=@Score_Type or Score_Type2=@Score_Type) or (Score_Type1 in (24,5) and @Score_Type in (245))
    or (Score_Type1 in (25,6,7) and @Score_Type in (2567)) or (Score_Type1 in (29,12,13) and @Score_Type in (291213))
    or (Score_Type1 in (10,26) and @Score_Type in (1026)))
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    

    -- 更新pYear_Score，更新下一阶段初始化状态
    ---- 非总部负责人、区域财务经理和营业部合规专员(Score_Type1 not in (1,17,14))
    update a
    set a.Initialized=1,a.InitializedBy=(select ID from SkySecUser where EID=@EID),a.InitializedTime=GETDATE()
    from pYear_Score a
    where a.EID in (select EID from pYear_Score where Score_EID=@EID and ISNULL(Submit,0)=1)
    and ((Score_Type1=@Score_Type or Score_Type2=@Score_Type) or (Score_Type1 in (24,5) and @Score_Type=245)
    or (Score_Type1 in (25,6,7) and @Score_Type=2567) or (Score_Type1 in (29,12,13) and @Score_Type=291213)
    or (Score_Type1 in (10,26) and @Score_Type=1026))
    and a.Score_Status=(select MIN(Score_Status) from pYear_Score 
    where ISNULL(Initialized,0)=0 and ((Score_Type1=@Score_Type or Score_Type2=@Score_Type) or (Score_Type1 in (24,5) and @Score_Type=245)
    or (Score_Type1 in (25,6,7) and @Score_Type=2567) or (Score_Type1 in (29,12,13) and @Score_Type=291213)
    or (Score_Type1 in (10,26) and @Score_Type=1026)))
    AND (select COUNT(Submit)/COUNT(ISNULL(Initialized,1)) from pYear_Score 
    where EID=a.EID and ((Score_Type1=@Score_Type or Score_Type2=@Score_Type) or (Score_Type1 in (24,5) and @Score_Type=245)
    or (Score_Type1 in (25,6,7) and @Score_Type=2567) or (Score_Type1 in (29,12,13) and @Score_Type=291213)
    or (Score_Type1 in (10,26) and @Score_Type=1026)) AND Score_Status=@Score_Status)=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM


    -- 更新最终评分及排名统计分数
    -- 总部部门负责人
    ---- Score_Status=2时ScoreSTG1
    ------ 战略企划部
    update a
    set a.ScoreSTG1=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and a.Score_Type1=1 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=3时ScoreSTG2
    ------ 分管领导(Director2)
    update a
    set a.ScoreSTG2=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=3
    and a.Score_Type1=1 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ------ 分管领导(Director2)为其他副职领导
    -------- update Score_Status=10:Score2,ScoreTotal
    update a
    set a.Score2=b.Score2,a.ScoreTotal=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=10 and b.Score_Status=4
    and b.Score_Type1=1 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -------- update Score_Status=9:ScoreSTG2
    update a
    set a.ScoreSTG2=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=10
    and b.Score_Type1=1 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ------ 分管领导(Director2)为主要领导
    -------- update Score_Status=10:Score3,ScoreTotal
    update a
    set a.Score2=b.Score2,a.ScoreTotal=b.ScoreTotal
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=10 and b.Score_Status=9
    and b.Score_Type1=1 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    -------- update Score_Status=9:ScoreSTG2
    update a
    set a.ScoreYear=a.ScoreEach+a.ScoreSTG1+a.ScoreSTG2+a.ScoreSTG3
    +(select AVG(ScoreTotal) from pYear_Score where EID=a.EID and Score_Status=9 and Score_Type1=1 and ISNULL(Submit,0)=1)*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=9
    and b.Score_Type1=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=4时ScoreSTG3
    ------ 其他副职领导
    ------ 其他副职领导非分管领导(Director2)
    update a
    set a.ScoreSTG3=(select AVG(ScoreTotal) from pYear_Score
    where EID=a.EID and Score_Status=4 and Score_Type1=1 and ISNULL(Submit,0)=1)*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=4
    and b.Score_Type1=1 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=9时ScoreYear
    ------ 主要领导
    ------ 主要领导非分管领导(Director2)
    update a
    set a.ScoreYear=a.ScoreEach+a.ScoreSTG1+a.ScoreSTG2+a.ScoreSTG3
    +(select AVG(ScoreTotal) from pYear_Score where EID=a.EID and Score_Status=a.Score_Status and Score_Type1=a.Score_Type1 and ISNULL(Submit,0)=1)*ISNULL(a.Modulus,100)/100
    from pYear_Score a
    where a.Score_Status=9 and a.Score_Type1=1
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    

    -- 子公司部门行政负责人
    ---- Score_Status=2时ScoreSTG1
    update a
    set a.ScoreSTG1=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1=10 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=3时ScoreSTG2
    update a
    set a.ScoreSTG2=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=3
    and b.Score_Type1=10 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 总部部门副职、分公司副职、一级营业部副职、二级营业部经理室成员
    ---- Score_Status=2时ScoreSTG1
    update a
    set a.ScoreSTG1=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1 in (2,25,6,7) and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 分公司负责人、一级营业部负责人
    ---- Score_Status=2时ScoreSTG1
    update a
    set a.ScoreSTG1=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1 in (24,5) and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=3时ScoreSTG2
    update a
    set a.ScoreSTG2=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=3
    and b.Score_Type1 in (24,5) and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=4时ScoreSTG3
    update a
    set a.ScoreSTG3=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=4
    and b.Score_Type1 in (24,5) and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=5时ScoreSTG4
    update a
    set a.ScoreSTG4=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=5
    and b.Score_Type1 in (24,5) and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 二级营业部普通员工
    ---- Score_Status=2时ScoreSTG1
    update a
    set a.ScoreSTG1=b.ScoreTotal*ISNULL(b.Weight1,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1=13 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 营业部合规风控专员
    ---- Score_Status=2时ScoreSTG1
    update a
    set a.ScoreSTG1=(select AVG(ScoreTotal) from pYear_Score 
    where EID=a.EID and Score_Status=2 and Score_Type1 in (14) and ISNULL(Submit,0)=1)*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1=14 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=3时ScoreSTG2
    update a
    set a.ScoreSTG2=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=3
    and b.Score_Type1=14 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 营业部区域财务经理
    ---- Score_Status=2时ScoreSTG1
    update a
    set a.ScoreSTG1=(select AVG(ScoreTotal) from pYear_Score 
    where EID=a.EID and Score_Status=2 and Score_Type1 in (17) and ISNULL(Submit,0)=1)*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1=17 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM
    ---- Score_Status=3时ScoreSTG2
    update a
    set a.ScoreSTG2=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=3
    and b.Score_Type1=17 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 综合会计
    ---- Score_Status=2时ScoreSTG1
    update a
    set a.ScoreSTG1=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=2
    and b.Score_Type1=19 and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM


    -- 总部兼职合规专员、营业部合规联系人
    ---- Score_Status=7时ScoreCompl
    update a
    set a.ScoreCompl=b.ScoreTotal*ISNULL(b.Modulus,100)/100
    from pYear_Score a,pYear_Score b
    where a.EID=b.EID and a.Score_Status=9 and b.Score_Status=7
    and b.Score_Type2 in (15,16) and b.Score_EID=@EID
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM


    -- 更新Ranking,RankLevel
    ---- Score_Status=9时
    update a
    set a.Ranking=b.Ranking,a.RankLevel=b.RankLevel
    from pYear_Score a,pVW_pYear_ScoreRanking b
    where a.EID=b.EID and a.Score_Status=9
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