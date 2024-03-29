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
    insert into pYear_DepAppraise (pYear_ID,AppraiseDepID,AppraiseEID)
    select distinct a.ID,b.DepID,b.Director
    from pYear_AppraiseProcess a,pVW_pYear_DepAppraise b
    where a.ID=@id and b.Director not in (select AppraiseEID from pYear_DepAppraise where ID=@id and b.DepID=AppraiseDepID)
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