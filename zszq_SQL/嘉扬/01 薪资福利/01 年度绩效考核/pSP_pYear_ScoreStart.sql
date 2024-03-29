USE [zszq]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- pSP_pYear_ScoreStart 9,1
ALTER  proc [dbo].[pSP_pYear_ScoreStart]
    @id int,
    @URID int,
    @RetVal int=0 output
as
/*
-- Create By wuliang E004205
-- 年度考核开启
*/
begin

    -- 上年度考核未关闭，无法再次开启
    if exists (select 1 from pYear_Process where id=@id-1 and isnull(Closed,0)=0)
    Begin
        Set @RetVal=1001010
        Return @RetVal
    End

    -- 年度考核已开启，无需重新开启！
    if exists (select 1 from pYear_Process where id=@id and isnull(Submit,0)=1)
    Begin
        Set @RetVal=1001020
        Return @RetVal
    End

    -- 年度考核已封帐，无法重新开启！
    if exists (select 1 from pYear_Process where id=@id and ISNULL(Closed,0)=1)
    Begin
        Set @RetVal=1001030
        Return @RetVal
    end


    BEGIN TRANSACTION

    -------- pYear_Score --------
    -- 添加员工打分排名表字段
    -- SCORE_STATUS初始值为9
    insert into pYear_Score (EID,pYear_ID,Score_Status,Score_Type1,Score_Type2,Score_EID,Score_DepID,Weight1,Weight2,Weight3,Modulus)
    select a.EID,@id,a.Score_Status,a.Score_Type1,a.Score_Type2,a.Score_EID,a.Score_DepID,a.Weight1,a.Weight2,a.Weight3,a.Modulus
    from pVW_pYear_ScoreType a,eEmployee b
    where a.EID=b.EID and b.Status in (1,2,3) and a.Score_Status=9
    and a.EID not in (select EID from pYear_Score where Score_Status=9)
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM

    -- 更新员工排名状态标记
    -- isranking：1-参加排名
    -- 年度考核本年度10月1日以后加入公司员工不参与排名
    update a
    set a.isranking=1
    from pYear_Score a,eStatus b,pYear_Process c
    where a.pYear_ID=C.ID and a.EID=b.EID and c.ID=@id and a.Score_Status=9
    and DateDiff(dd,b.JoinDate,convert(varchar(4),c.Date ,120)+'-10-01')>=0
    -- 异常处理
    if @@ERROR<>0
    GOTO ErrM

    -- 更新部门人数和部门排名人数
    update a
    set a.TotalNum=b.TotalNum,a.TotalRankNum=b.TotalRankNum
    from pYear_Score a,pVW_pYear_ScoreRanking b
    where a.EID=b.EID and a.Score_Status=9
    -- 异常处理
    IF @@Error <> 0
    Goto ErrM


    -------- pYear_Process --------
    -- 更新流程信息为开启
    update pYear_Process
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