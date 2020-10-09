SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE	@ClientID	INT
	,	@LobCode	VARCHAR(5)
	,	@StartDate	DATE
	,	@EndDate	DATE

SET	@ClientID = 26
SET	@LobCode = 'MC'
SET	@StartDate = '2020-09-01'
SET @EndDate = '2020-09-30'

select	distinct a11.DIAGNOSIS_KEY  DIAGNOSIS_KEY,
	a12.Reference_Number  Reference_Number,
	a13.PlaceofServiceKey  Place_of_Service_Key,
	a14.LOB_CODE  LOB_CODE,
	a14.LOB_DESC  LOB_DESC,
	a15.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	a16.DATE  DATE,
	a14.CLIENT_ID  CLIENT_ID,
	a12.IsPrimaryDiag  IsPrimaryDiag,
	CONCAT(a11.DIAGNOSIS_ICD_CODE, ' - ', a11.DIAGNOSIS_SHORT_DESC)  WJXBFS1
into	#diagnosis_details
from	DIAGNOSIS_DIM	a11 WITH (NOLOCK)
	left outer join	vw_Fact_UM_Diagnosis	a12 WITH (NOLOCK)
	  on 	(a11.DIAGNOSIS_KEY = a12.DIAGNOSIS_KEY)
	left outer join	IdentifiRpt.UM_RequestFact	a13 WITH (NOLOCK)
	  on 	(a12.Auth_Request_Key = a13.AuthRequestKey)
	left outer join	PLAN_DIM	a14 WITH (NOLOCK)
	  on 	(a13.PlanDimKey = a14.PLAN_DIM_KEY)
	left outer join	IdentifiRpt.UM_ReviewLineDetailFact	a15 WITH (NOLOCK)
	  on 	(a12.Auth_Request_Key = a15.AuthRequestKey and 
	a13.AuthRequestKey = a15.AuthRequestKey and 
	a13.ServiceReviewTypeKey = a15.AuthReviewServiceReviewTypeKey)
	left outer join	DATE_DIM	a16 WITH (NOLOCK)
	  on 	(a15.AuthReviewUMFinalDecisionDateDimKey = a16.DATE_DIM_KEY)
where	(a15.AuthReviewPriorityKey in (2, 4)
 and a13.IsPreDetermination in (1)
 and a15.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a15.AuthReviewTypeKey in (1)
 and a14.CLIENT_ID in (@ClientID)
 and a14.LOB_CODE in (@LobCode)
 and a16.DATE between @StartDate and @EndDate)

create table ##THK5BKU6VMD000
(
	Reference_Number			VARCHAR(50), 
	Place_of_Service_Key		INTEGER, 
	LOB_CODE					VARCHAR(5), 
	LOB_DESC					VARCHAR(50), 
	DATE_DIM_KEY				BIGINT, 
	DATE						DATE, 
	CLIENT_ID					INTEGER, 
	FINALDIAGNOSISFORAUTHREQ	NVARCHAR(100)
)

insert into ##THK5BKU6VMD000 (Reference_Number, Place_of_Service_Key, LOB_CODE, LOB_DESC, DATE_DIM_KEY, DATE, CLIENT_ID, FINALDIAGNOSISFORAUTHREQ)
select	Reference_Number
	,	Place_of_Service_Key
	,	LOB_CODE
	,	LOB_DESC
	,	DATE_DIM_KEY
	,	DATE
	,	CLIENT_ID
	,	LEFT(STUFF((SELECT ', ' + WJXBFS1  
					FROM #diagnosis_details dg1
					WHERE dg1.Reference_Number = dg2.Reference_Number
						AND	dg1.DATE_DIM_KEY = dg2.DATE_DIM_KEY
						AND	dg1.Place_of_Service_Key = dg2.Place_of_Service_Key
					ORDER BY [IsPrimaryDiag] DESC
					FOR XML PATH('')),1,1,''), 100)
from	#diagnosis_details dg2

select	a14.ReviewReceivedDateDimKey  ReviewReceivedDateDimKey,
	a16.RequestorTypeKey  Requestor_Type_Key,
	a16.AuthTypeKey  Auth_Type_Key,
	a11.ReferenceNumber  Reference_Number,
	a13.PLAN_ID  CustCol_306,
	a16.PlaceofServiceKey  Place_of_Service_Key,
	a17.MEMBER_NBR  MEMBER_NBR,
	a17.LAST_NAME  LAST_NAME,
	max(left(a17.LAST_NAME,50))  CustCol_310,
	a17.FIRST_NAME  FIRST_NAME,
	max(left(a17.FIRST_NAME,50))  CustCol_309,
	a12.LOB_CODE  LOB_CODE,
	max(a12.LOB_DESC)  LOB_DESC,
	a16.IsPreDetermination  IsPreDetermination,
	(Case when a15.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end)  CustCol_142,
	CASE WHEN a14.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a14.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END  DATE_SERVICE_AUTH_IN_SPON_SYS,
	a14.AuthReviewUMFinalStatusKey  Review_Status_Key,
	a14.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	max(a18.DATE)  DATE0,
	a13.CONTRACT_ID  CustCol_305,
	a11.ClientID  CLIENT_ID,
	max(CASE WHEN a11.ContactCategoryKey IN (1,2,3,4,5,6,24,26,1032,1060,1061,1067,1068,1069,3001,20003) AND a11.CareNoteCategoryKey = 3003 AND a11.CareNoteActionKey IN (3014,3016,3066,3067,3099) AND a11.CareNoteResponseKey IN (8,37,38) THEN convert(date,a11.CareNoteDateTime) ELSE '1900-01-01' END)  DATEOFORALNOTIFICATION
into ##T207JC9P3MD001
from	IdentifiRpt.CareNoteFact	a11 WITH (NOLOCK)
	left outer join	PLAN_DIM	a12 WITH (NOLOCK)
	  on 	(a11.PlanDimKey = a12.PLAN_DIM_KEY)
	left outer join	MStrategy_Trans.dbo.MSTR_UNIVERSES_CLIENT	a13 WITH (NOLOCK)
	  on 	(a11.ClientID = a13.CLIENT_ID and 
	a12.LOB_CODE = a13.LOB_CODE and 
	a12.PLAN_DESC_IDCARD = a13.PLAN_DESC_IDCARD)
	left outer join	IdentifiRpt.UM_ReviewLineDetailFact	a14 WITH (NOLOCK)
	  on 	(a11.AuthReviewKey = a14.AuthReviewKey)
	left outer join	VW_Fact_UM_Providers	a15 WITH (NOLOCK)
	  on 	(a11.AuthRequestKey = a15.AuthRequestKey)
	left outer join	IdentifiRpt.UM_RequestFact	a16 WITH (NOLOCK)
	  on 	(a11.AuthRequestKey = a16.AuthRequestKey and 
	a14.AuthRequestKey = a16.AuthRequestKey and 
	a14.AuthReviewServiceReviewTypeKey = a16.ServiceReviewTypeKey)
	left outer join	MEMBER_DIM	a17 WITH (NOLOCK)
	  on 	(a11.MemberDimKey = a17.MEMBER_DIM_KEY)
	left outer join	DATE_DIM	a18 WITH (NOLOCK)
	  on 	(a14.AuthReviewUMFinalDecisionDateDimKey = a18.DATE_DIM_KEY)
where	(a14.AuthReviewPriorityKey in (2, 4)
 and a16.IsPreDetermination in (1)
 and a14.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a14.AuthReviewTypeKey in (1)
 and a11.ClientID in (26)
 and a12.LOB_CODE in (@LobCode)
 and a18.DATE between @StartDate and @EndDate)
group by	a14.ReviewReceivedDateDimKey,
	a16.RequestorTypeKey,
	a16.AuthTypeKey,
	a11.ReferenceNumber,
	a13.PLAN_ID,
	a16.PlaceofServiceKey,
	a17.MEMBER_NBR,
	a17.LAST_NAME,
	a17.FIRST_NAME,
	a12.LOB_CODE,
	a16.IsPreDetermination,
	(Case when a15.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end),
	CASE WHEN a14.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a14.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END,
	a14.AuthReviewUMFinalStatusKey,
	a14.AuthReviewUMFinalDecisionDateDimKey,
	a13.CONTRACT_ID,
	a11.ClientID 

select	a14.ReviewReceivedDateDimKey  ReviewReceivedDateDimKey,
	a16.RequestorTypeKey  Requestor_Type_Key,
	a16.AuthTypeKey  Auth_Type_Key,
	a11.ReferenceNumber  Reference_Number,
	a13.PLAN_ID  CustCol_306,
	a16.PlaceofServiceKey  Place_of_Service_Key,
	a17.MEMBER_NBR  MEMBER_NBR,
	a17.LAST_NAME  LAST_NAME,
	max(left(a17.LAST_NAME,50))  CustCol_310,
	a17.FIRST_NAME  FIRST_NAME,
	max(left(a17.FIRST_NAME,50))  CustCol_309,
	a12.LOB_CODE  LOB_CODE,
	max(a12.LOB_DESC)  LOB_DESC,
	a16.IsPreDetermination  IsPreDetermination,
	(Case when a15.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end)  CustCol_142,
	CASE WHEN a14.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a14.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END  DATE_SERVICE_AUTH_IN_SPON_SYS,
	a14.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	max(a18.DATE)  DATE0,
	a13.CONTRACT_ID  CustCol_305,
	a11.ClientID  CLIENT_ID,
	min(CASE WHEN a11.ContactCategoryKey IN (2,3,4,5,6,24,26,1060,1061,1067,1068,1069,3001,20003) 
AND a11.CareNoteCategoryKey = 3
AND a11.CareNoteActionKey = 3050
AND a11.CareNoteRelatedToKey = 9 
THEN convert(date,a11.CareNoteDateTime)
ELSE '8999-01-01'END)  AORRECEIPTDATEREVIEWLEVEL,
	min(CASE WHEN a11.ContactCategoryKey IN (2,3,4,5,6,24,26,1060,1061,1067,1068,1069,3001,20003) 
AND a11.CareNoteCategoryKey = 3
AND a11.CareNoteActionKey = 3050
AND a11.CareNoteRelatedToKey = 8 
THEN convert(date,a11.CareNoteDateTime) 
ELSE '8999-01-01' END)  AORRECEIPTDATEREQUESTLEVEL
into ##TO64DK9EFMD002
from	IdentifiRpt.CareNoteFact	a11 WITH (NOLOCK)
	left outer join	PLAN_DIM	a12 WITH (NOLOCK)
	  on 	(a11.PlanDimKey = a12.PLAN_DIM_KEY)
	left outer join	MStrategy_Trans.dbo.MSTR_UNIVERSES_CLIENT	a13 WITH (NOLOCK)
	  on 	(a11.ClientID = a13.CLIENT_ID and 
	a12.LOB_CODE = a13.LOB_CODE and 
	a12.PLAN_DESC_IDCARD = a13.PLAN_DESC_IDCARD)
	left outer join	IdentifiRpt.UM_ReviewLineDetailFact	a14 WITH (NOLOCK)
	  on 	(a11.AuthReviewKey = a14.AuthReviewKey)
	left outer join	VW_Fact_UM_Providers	a15 WITH (NOLOCK)
	  on 	(a11.AuthRequestKey = a15.AuthRequestKey)
	left outer join	IdentifiRpt.UM_RequestFact	a16 WITH (NOLOCK)
	  on 	(a11.AuthRequestKey = a16.AuthRequestKey and 
	a14.AuthRequestKey = a16.AuthRequestKey and 
	a14.AuthReviewServiceReviewTypeKey = a16.ServiceReviewTypeKey)
	left outer join	MEMBER_DIM	a17 WITH (NOLOCK)
	  on 	(a11.MemberDimKey = a17.MEMBER_DIM_KEY)
	left outer join	DATE_DIM	a18 WITH (NOLOCK)
	  on 	(a14.AuthReviewUMFinalDecisionDateDimKey = a18.DATE_DIM_KEY)
where	(a14.AuthReviewPriorityKey in (2, 4)
 and a16.IsPreDetermination in (1)
 and a14.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a14.AuthReviewTypeKey in (1)
 and a11.ClientID in (26)
 and a12.LOB_CODE in (@LobCode)
 and a18.DATE between @StartDate and @EndDate
 and a16.RequestorTypeKey in (14))
group by	a14.ReviewReceivedDateDimKey,
	a16.RequestorTypeKey,
	a16.AuthTypeKey,
	a11.ReferenceNumber,
	a13.PLAN_ID,
	a16.PlaceofServiceKey,
	a17.MEMBER_NBR,
	a17.LAST_NAME,
	a17.FIRST_NAME,
	a12.LOB_CODE,
	a16.IsPreDetermination,
	(Case when a15.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end),
	CASE WHEN a14.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a14.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END,
	a14.AuthReviewUMFinalDecisionDateDimKey,
	a13.CONTRACT_ID,
	a11.ClientID 

select	CASE WHEN a12.AuthReviewUMFinalStatusKey = 3 THEN 'NA' ELSE CASE WHEN a12.AuthReviewUMFinalDenialReasonKey IN (3, 4, 10, 33) THEN 'Y' ELSE 'N' END END  Denied_For_Lack_Of_Medical_Necessity,
	'N'  Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe,
	CASE WHEN a12.AuthReviewPriorityKey=4 THEN 'Y' ELSE 'N' END  Was_A_Timeframe_Extension_Taken,
	a12.AuthReviewTypeKey  Review_Type_Key,
	a12.ReviewReceivedDateDimKey  ReviewReceivedDateDimKey,
	a12.AuthReviewPriorityKey  Review_Priority_Key,
	a13.RequestorTypeKey  Requestor_Type_Key,
	a13.AuthTypeKey  Auth_Type_Key,
	a13.ReferenceNumber  Reference_Number,
	a15.PLAN_ID  CustCol_306,
	a13.PlaceofServiceKey  Place_of_Service_Key,
	a17.MEMBER_NBR  MEMBER_NBR,
	a17.LAST_NAME  LAST_NAME,
	max(left(a17.LAST_NAME,50))  CustCol_310,
	a17.FIRST_NAME  FIRST_NAME,
	max(left(a17.FIRST_NAME,50))  CustCol_309,
	a14.LOB_CODE  LOB_CODE,
	max(a14.LOB_DESC)  LOB_DESC,
	a13.IsPreDetermination  IsPreDetermination,
	case when a12.AuthReviewPriorityKey=4 then ' ' else 'NA' end  If_Extension_was_Taken_Did_Sponsor,
	'Evolent Health'  CustCol_322,
	(Case when a16.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end)  CustCol_142,
	a11.Denial_Reason_Key  Denial_Reason_Key,
	max(a11.Denial_Reason_Desc)  Denial_Reason_Desc,
	CASE WHEN a12.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a12.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END  DATE_SERVICE_AUTH_IN_SPON_SYS,
	a12.AuthReviewUMFinalStatusKey  Review_Status_Key,
	a12.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	max(a18.DATE)  DATE0,
	a15.CONTRACT_ID  CustCol_305,
	a14.CLIENT_ID  CLIENT_ID,
	max(a11.Denial_Reason_Desc)  IDTSWITHDENIALREASON
into ##TWPKGGT6VMD003
from	VW_Dim_UM_Denial_Reason	a11 WITH (NOLOCK)
	left outer join	IdentifiRpt.UM_ReviewLineDetailFact	a12 WITH (NOLOCK)
	  on 	(a11.Denial_Reason_Key = a12.AuthReviewUMFinalDenialReasonKey)
	left outer join	IdentifiRpt.UM_RequestFact	a13 WITH (NOLOCK)
	  on 	(a12.AuthRequestKey = a13.AuthRequestKey and 
	a12.AuthReviewServiceReviewTypeKey = a13.ServiceReviewTypeKey)
	left outer join	PLAN_DIM	a14 WITH (NOLOCK)
	  on 	(a13.PlanDimKey = a14.PLAN_DIM_KEY)
	left outer join	MStrategy_Trans.dbo.MSTR_UNIVERSES_CLIENT	a15 WITH (NOLOCK)
	  on 	(a14.CLIENT_ID = a15.CLIENT_ID and 
	a14.LOB_CODE = a15.LOB_CODE and 
	a14.PLAN_DESC_IDCARD = a15.PLAN_DESC_IDCARD)
	left outer join	VW_Fact_UM_Providers	a16 WITH (NOLOCK)
	  on 	(a12.AuthRequestKey = a16.AuthRequestKey)
	left outer join	MEMBER_DIM	a17 WITH (NOLOCK)
	  on 	(a13.MemberDimKey = a17.MEMBER_DIM_KEY)
	left outer join	DATE_DIM	a18 WITH (NOLOCK)
	  on 	(a12.AuthReviewUMFinalDecisionDateDimKey = a18.DATE_DIM_KEY)
where	(a12.AuthReviewPriorityKey in (2, 4)
 and a13.IsPreDetermination in (1)
 and a12.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a12.AuthReviewTypeKey in (1)
 and a14.CLIENT_ID in (@ClientID)
 and a14.LOB_CODE in (@LobCode)
 and a18.DATE between @StartDate and @EndDate
 and a11.Denial_Reason_Key is not null)
group by	CASE WHEN a12.AuthReviewUMFinalStatusKey = 3 THEN 'NA' ELSE CASE WHEN a12.AuthReviewUMFinalDenialReasonKey IN (3, 4, 10, 33) THEN 'Y' ELSE 'N' END END,
	CASE WHEN a12.AuthReviewPriorityKey=4 THEN 'Y' ELSE 'N' END,
	a12.AuthReviewTypeKey,
	a12.ReviewReceivedDateDimKey,
	a12.AuthReviewPriorityKey,
	a13.RequestorTypeKey,
	a13.AuthTypeKey,
	a13.ReferenceNumber,
	a15.PLAN_ID,
	a13.PlaceofServiceKey,
	a17.MEMBER_NBR,
	a17.LAST_NAME,
	a17.FIRST_NAME,
	a14.LOB_CODE,
	a13.IsPreDetermination,
	case when a12.AuthReviewPriorityKey=4 then ' ' else 'NA' end,
	(Case when a16.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end),
	a11.Denial_Reason_Key,
	CASE WHEN a12.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a12.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END,
	a12.AuthReviewUMFinalStatusKey,
	a12.AuthReviewUMFinalDecisionDateDimKey,
	a15.CONTRACT_ID,
	a14.CLIENT_ID 

select	CASE WHEN a12.AuthReviewUMFinalStatusKey = 3 THEN 'NA' ELSE CASE WHEN a12.AuthReviewUMFinalDenialReasonKey IN (3, 4, 10, 33) THEN 'Y' ELSE 'N' END END  Denied_For_Lack_Of_Medical_Necessity,
	'N'  Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe,
	CASE WHEN a12.AuthReviewPriorityKey=4 THEN 'Y' ELSE 'N' END  Was_A_Timeframe_Extension_Taken,
	a12.AuthReviewTypeKey  Review_Type_Key,
	a12.ReviewReceivedDateDimKey  ReviewReceivedDateDimKey,
	a12.AuthReviewPriorityKey  Review_Priority_Key,
	a13.RequestorTypeKey  Requestor_Type_Key,
	a13.AuthTypeKey  Auth_Type_Key,
	a13.ReferenceNumber  Reference_Number,
	a15.PLAN_ID  CustCol_306,
	a13.PlaceofServiceKey  Place_of_Service_Key,
	a17.MEMBER_NBR  MEMBER_NBR,
	a17.LAST_NAME  LAST_NAME,
	max(left(a17.LAST_NAME,50))  CustCol_310,
	a17.FIRST_NAME  FIRST_NAME,
	max(left(a17.FIRST_NAME,50))  CustCol_309,
	a14.LOB_CODE  LOB_CODE,
	max(a14.LOB_DESC)  LOB_DESC,
	a13.IsPreDetermination  IsPreDetermination,
	case when a12.AuthReviewPriorityKey=4 then ' ' else 'NA' end  If_Extension_was_Taken_Did_Sponsor,
	'Evolent Health'  CustCol_322,
	(Case when a16.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end)  CustCol_142,
	a12.AuthReviewUMFinalDenialReasonKey  Denial_Reason_Key,
	CASE WHEN a12.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a12.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END  DATE_SERVICE_AUTH_IN_SPON_SYS,
	a12.AuthReviewUMFinalStatusKey  Review_Status_Key,
	a12.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	max(a18.DATE)  DATE0,
	a15.CONTRACT_ID  CustCol_305,
	a14.CLIENT_ID  CLIENT_ID,
	min(a11.MailStatusDateTime)  MAILSUCCESSDATE,
	CAST(min(a11.MailStatusDateTime) AS DATE)  WJXBFS1
into ##TXPYCNDTZMD004
from	MStrategy_Trans.dbo.VW_MSTR_UNIVERSE1_ISENTKEY	a11 WITH (NOLOCK)
	left outer join	IdentifiRpt.UM_ReviewLineDetailFact	a12 WITH (NOLOCK)
	  on 	(a11.AuthRequestKey = a12.AuthRequestKey and 
	a11.EntityKey = a12.ISentKey)
	left outer join	IdentifiRpt.UM_RequestFact	a13 WITH (NOLOCK)
	  on 	(a12.AuthRequestKey = a13.AuthRequestKey and 
	a12.AuthReviewServiceReviewTypeKey = a13.ServiceReviewTypeKey)
	left outer join	PLAN_DIM	a14 WITH (NOLOCK)
	  on 	(a13.PlanDimKey = a14.PLAN_DIM_KEY)
	left outer join	MStrategy_Trans.dbo.MSTR_UNIVERSES_CLIENT	a15 WITH (NOLOCK)
	  on 	(a14.CLIENT_ID = a15.CLIENT_ID and 
	a14.LOB_CODE = a15.LOB_CODE and 
	a14.PLAN_DESC_IDCARD = a15.PLAN_DESC_IDCARD)
	left outer join	VW_Fact_UM_Providers	a16 WITH (NOLOCK)
	  on 	(a12.AuthRequestKey = a16.AuthRequestKey)
	left outer join	MEMBER_DIM	a17 WITH (NOLOCK)
	  on 	(a13.MemberDimKey = a17.MEMBER_DIM_KEY)
	left outer join	DATE_DIM	a18 WITH (NOLOCK)
	  on 	(a12.AuthReviewUMFinalDecisionDateDimKey = a18.DATE_DIM_KEY)
where	(a12.AuthReviewPriorityKey in (2, 4)
 and a13.IsPreDetermination in (1)
 and a12.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a12.AuthReviewTypeKey in (1)
 and a14.CLIENT_ID in (@ClientID)
 and a14.LOB_CODE in (@LobCode)
 and a18.DATE between @StartDate and @EndDate)
group by	CASE WHEN a12.AuthReviewUMFinalStatusKey = 3 THEN 'NA' ELSE CASE WHEN a12.AuthReviewUMFinalDenialReasonKey IN (3, 4, 10, 33) THEN 'Y' ELSE 'N' END END,
	CASE WHEN a12.AuthReviewPriorityKey=4 THEN 'Y' ELSE 'N' END,
	a12.AuthReviewTypeKey,
	a12.ReviewReceivedDateDimKey,
	a12.AuthReviewPriorityKey,
	a13.RequestorTypeKey,
	a13.AuthTypeKey,
	a13.ReferenceNumber,
	a15.PLAN_ID,
	a13.PlaceofServiceKey,
	a17.MEMBER_NBR,
	a17.LAST_NAME,
	a17.FIRST_NAME,
	a14.LOB_CODE,
	a13.IsPreDetermination,
	case when a12.AuthReviewPriorityKey=4 then ' ' else 'NA' end,
	(Case when a16.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end),
	a12.AuthReviewUMFinalDenialReasonKey,
	CASE WHEN a12.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a12.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END,
	a12.AuthReviewUMFinalStatusKey,
	a12.AuthReviewUMFinalDecisionDateDimKey,
	a15.CONTRACT_ID,
	a14.CLIENT_ID 

select	a11.ReviewReceivedDateDimKey  ReviewReceivedDateDimKey,
	a12.RequestorTypeKey  Requestor_Type_Key,
	a12.AuthTypeKey  Auth_Type_Key,
	a12.ReferenceNumber  Reference_Number,
	a14.PLAN_ID  CustCol_306,
	a12.PlaceofServiceKey  Place_of_Service_Key,
	a16.MEMBER_NBR  MEMBER_NBR,
	a16.LAST_NAME  LAST_NAME,
	max(left(a16.LAST_NAME,50))  CustCol_310,
	a16.FIRST_NAME  FIRST_NAME,
	max(left(a16.FIRST_NAME,50))  CustCol_309,
	a13.LOB_CODE  LOB_CODE,
	max(a13.LOB_DESC)  LOB_DESC,
	a12.IsPreDetermination  IsPreDetermination,
	(Case when a15.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end)  CustCol_142,
	CASE WHEN a11.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a11.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END  DATE_SERVICE_AUTH_IN_SPON_SYS,
	a11.AuthReviewUMFinalStatusKey  Review_Status_Key,
	a11.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	max(a17.DATE)  DATE0,
	a14.CONTRACT_ID  CustCol_305,
	a13.CLIENT_ID  CLIENT_ID,
	min(case 
when DATEPART(WEEKDAY, a11.FirstPrintDate) IN (2, 3, 4, 5, 6) AND CONVERT(TIME(0), a11.FirstPrintDate, 121) < CONVERT(TIME(0), '10:00:00', 121) then convert(date, a11.FirstPrintDate)
when DATEPART(WEEKDAY, a11.FirstPrintDate) IN (1, 2, 3, 4, 5) then convert(date, DATEADD(DD, 1, a11.FirstPrintDate))
when DATEPART(WEEKDAY, a11.FirstPrintDate) = 6 then convert(date, DATEADD(DD, 3, a11.FirstPrintDate))
when DATEPART(WEEKDAY, a11.FirstPrintDate) = 7 then convert(date, DATEADD(DD, 2, a11.FirstPrintDate))
else null end)  FIRSTPRINTDATE,
	CAST(min(case 
when DATEPART(WEEKDAY, a11.FirstPrintDate) IN (2, 3, 4, 5, 6) AND CONVERT(TIME(0), a11.FirstPrintDate, 121) < CONVERT(TIME(0), '10:00:00', 121) then convert(date, a11.FirstPrintDate)
when DATEPART(WEEKDAY, a11.FirstPrintDate) IN (1, 2, 3, 4, 5) then convert(date, DATEADD(DD, 1, a11.FirstPrintDate))
when DATEPART(WEEKDAY, a11.FirstPrintDate) = 6 then convert(date, DATEADD(DD, 3, a11.FirstPrintDate))
when DATEPART(WEEKDAY, a11.FirstPrintDate) = 7 then convert(date, DATEADD(DD, 2, a11.FirstPrintDate))
else null end) AS DATE)  WJXBFS1
into ##TQ98OVEC7MD005
from	IdentifiRpt.UM_ReviewLineDetailFact	a11 WITH (NOLOCK)
	left outer join	IdentifiRpt.UM_RequestFact	a12 WITH (NOLOCK)
	  on 	(a11.AuthRequestKey = a12.AuthRequestKey and 
	a11.AuthReviewServiceReviewTypeKey = a12.ServiceReviewTypeKey)
	left outer join	PLAN_DIM	a13 WITH (NOLOCK)
	  on 	(a12.PlanDimKey = a13.PLAN_DIM_KEY)
	left outer join	MStrategy_Trans.dbo.MSTR_UNIVERSES_CLIENT	a14 WITH (NOLOCK)
	  on 	(a13.CLIENT_ID = a14.CLIENT_ID and 
	a13.LOB_CODE = a14.LOB_CODE and 
	a13.PLAN_DESC_IDCARD = a14.PLAN_DESC_IDCARD)
	left outer join	VW_Fact_UM_Providers	a15 WITH (NOLOCK)
	  on 	(a11.AuthRequestKey = a15.AuthRequestKey)
	left outer join	MEMBER_DIM	a16 WITH (NOLOCK)
	  on 	(a12.MemberDimKey = a16.MEMBER_DIM_KEY)
	left outer join	DATE_DIM	a17 WITH (NOLOCK)
	  on 	(a11.AuthReviewUMFinalDecisionDateDimKey = a17.DATE_DIM_KEY)
where	((exists (select	*
	from	IdentifiRpt.LetterFact	c21 WITH (NOLOCK)
		left outer join	PLAN_DIM	c22 WITH (NOLOCK)
		  on 	(c21.PlanDimKey = c22.PLAN_DIM_KEY)
		left outer join	MStrategy_Trans.dbo.MSTR_UNIVERSES_CLIENT	c23 WITH (NOLOCK)
		  on 	(c21.ClientID = c23.CLIENT_ID and 
		c22.LOB_CODE = c23.LOB_CODE and 
		c22.PLAN_DESC_IDCARD = c23.PLAN_DESC_IDCARD)
	where	(c21.LetterType in ('LetterOut')
	 and c21.LetterCategoryDesc in ('UM Approve Full', 'UM Approve Partial', 'UM Deny'))
	 and	c23.PLAN_ID = a14.PLAN_ID
	 and 	c22.LOB_CODE = a13.LOB_CODE
	 and 	c23.CONTRACT_ID = a14.CONTRACT_ID
	 and 	c21.ClientID = a13.CLIENT_ID))
 and a12.IsPreDetermination in (1)
 and a11.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a11.AuthReviewTypeKey in (1)
 and a13.CLIENT_ID in (@ClientID)
 and a13.LOB_CODE in (@LobCode)
 and a17.DATE between @StartDate and @EndDate
 and a11.AuthReviewPriorityKey in (2, 4))
group by	a11.ReviewReceivedDateDimKey,
	a12.RequestorTypeKey,
	a12.AuthTypeKey,
	a12.ReferenceNumber,
	a14.PLAN_ID,
	a12.PlaceofServiceKey,
	a16.MEMBER_NBR,
	a16.LAST_NAME,
	a16.FIRST_NAME,
	a13.LOB_CODE,
	a12.IsPreDetermination,
	(Case when a15.FacilityProviderIsINN = 1 then 'In Network' else 'Out of Network' end),
	CASE WHEN a11.AuthReviewUMFinalStatusKey=3 THEN CONVERT(DATE,a11.AuthReviewUMFinalDecisionDateTime) ELSE '1900-01-01' END,
	a11.AuthReviewUMFinalStatusKey,
	a11.AuthReviewUMFinalDecisionDateDimKey,
	a14.CONTRACT_ID,
	a13.CLIENT_ID 

select	distinct a11.ProcedureCode  ICD_PROCEDURE_KEY,
	a11.ProcedureDesc  ICD_PROCEDURE_DESC,
	a12.ReviewReceivedDateDimKey  ReviewReceivedDateDimKey,
	a12.AuthReviewPriorityKey  Review_Priority_Key,
	a13.ReferenceNumber  Reference_Number,
	a14.LOB_CODE  LOB_CODE,
	a14.LOB_DESC  LOB_DESC,
	a12.AuthReviewUMFinalDenialReasonKey  Denial_Reason_Key,
	a12.AuthReviewUMFinalStatusKey  Review_Status_Key,
	a12.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	a15.DATE  DATE0,
	a14.CLIENT_ID  CLIENT_ID,
	a11.ProcedureDesc  WJXBFS1
into	#procedure_details
from	VW_Dim_UM_Procedures	a11 WITH (NOLOCK)
	left outer join	IdentifiRpt.UM_ReviewLineDetailFact	a12 WITH (NOLOCK)
	  on 	(a11.ProcedureCode = a12.ProcedureCode)
	left outer join	IdentifiRpt.UM_RequestFact	a13 WITH (NOLOCK)
	  on 	(a12.AuthRequestKey = a13.AuthRequestKey and 
	a12.AuthReviewServiceReviewTypeKey = a13.ServiceReviewTypeKey)
	left outer join	PLAN_DIM	a14 WITH (NOLOCK)
	  on 	(a13.PlanDimKey = a14.PLAN_DIM_KEY)
	left outer join	DATE_DIM	a15 WITH (NOLOCK)
	  on 	(a12.AuthReviewUMFinalDecisionDateDimKey = a15.DATE_DIM_KEY)
where	(a12.AuthReviewPriorityKey in (2, 4)
 and a13.IsPreDetermination in (1)
 and a12.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a12.AuthReviewTypeKey in (1)
 and a14.CLIENT_ID in (@ClientID)
 and a14.LOB_CODE in (@LobCode)
 and a15.DATE between @StartDate and @EndDate
 and a11.ProcedureDesc is not null)

create table ##TVEGXHE93MD006
(
	ReviewReceivedDateDimKey	BIGINT, 
	Review_Priority_Key	TINYINT, 
	Reference_Number	VARCHAR(50), 
	LOB_CODE	VARCHAR(5), 
	LOB_DESC	VARCHAR(50), 
	Denial_Reason_Key	INTEGER, 
	Review_Status_Key	TINYINT, 
	DATE_DIM_KEY	BIGINT, 
	DATE0	DATE, 
	CLIENT_ID	INTEGER, 
	IDTSWITHPROCDESC	NVARCHAR(2000), 
	IDTSWITHPROCDESCFORDENIALS	NVARCHAR(2000)
)

insert into ##TVEGXHE93MD006 (ReviewReceivedDateDimKey, Review_Priority_Key, Reference_Number, LOB_CODE, LOB_DESC, Denial_Reason_Key, Review_Status_Key, DATE_DIM_KEY, DATE0, CLIENT_ID, IDTSWITHPROCDESC, IDTSWITHPROCDESCFORDENIALS)
select	ReviewReceivedDateDimKey
	,	Review_Priority_Key
	,	Reference_Number
	,	LOB_CODE
	,	LOB_DESC
	,	Denial_Reason_Key
	,	Review_Status_Key
	,	DATE_DIM_KEY
	,	DATE0
	,	CLIENT_ID
	,	LEFT(STUFF((SELECT ', ' + WJXBFS1
					FROM	#procedure_details pd1
					WHERE	pd1.Reference_Number = pd2.Reference_Number
						AND	pd1.Review_Status_Key = pd2.Review_Status_Key
						AND	pd1.ReviewReceivedDateDimKey = pd2.ReviewReceivedDateDimKey
						AND	pd1.DATE_DIM_KEY = pd2.DATE_DIM_KEY
						AND pd1.Review_Priority_Key = pd2.Review_Priority_Key
					ORDER BY [ICD_PROCEDURE_DESC] DESC
					FOR XML PATH('')),1,1,''), 2000)
	,	LEFT(STUFF((SELECT ', ' + WJXBFS1
					FROM	#procedure_details pd1
					WHERE	pd1.Reference_Number = pd2.Reference_Number
						AND	pd1.Review_Status_Key = pd2.Review_Status_Key
						AND	pd1.ReviewReceivedDateDimKey = pd2.ReviewReceivedDateDimKey
						AND	pd1.DATE_DIM_KEY = pd2.DATE_DIM_KEY
						AND pd1.Review_Priority_Key = pd2.Review_Priority_Key
					ORDER BY [ICD_PROCEDURE_DESC] DESC
					FOR XML PATH('')),1,1,''), 2000)
from	#procedure_details pd2

select	distinct a12.ReviewReceivedDateDimKey  ReviewReceivedDateDimKey,
	a12.AuthReviewPriorityKey  Review_Priority_Key,
	a13.ReferenceNumber  Reference_Number,
	a11.DenialText  DenialText,
	a14.LOB_CODE  LOB_CODE,
	a14.LOB_DESC  LOB_DESC,
	a12.AuthReviewUMFinalDenialReasonKey  Denial_Reason_Key,
	a12.AuthReviewUMFinalStatusKey  Review_Status_Key,
	a12.AuthReviewUMFinalDecisionDateDimKey  DATE_DIM_KEY,
	a15.DATE  DATE0,
	a14.CLIENT_ID  CLIENT_ID,
	a11.DenialText  WJXBFS1
into	#denial_texts
from	IdentifiRpt.UM_ReviewLineDetailFact	a11 WITH (NOLOCK)
	left outer join	IdentifiRpt.UM_ReviewLineDetailFact	a12 WITH (NOLOCK)
	  on 	(a11.DenialText = a12.DenialText)
	left outer join	IdentifiRpt.UM_RequestFact	a13 WITH (NOLOCK)
	  on 	(a12.AuthRequestKey = a13.AuthRequestKey and 
	a12.AuthReviewServiceReviewTypeKey = a13.ServiceReviewTypeKey)
	left outer join	PLAN_DIM	a14 WITH (NOLOCK)
	  on 	(a13.PlanDimKey = a14.PLAN_DIM_KEY)
	left outer join	DATE_DIM	a15 WITH (NOLOCK)
	  on 	(a12.AuthReviewUMFinalDecisionDateDimKey = a15.DATE_DIM_KEY)
where	(a12.AuthReviewPriorityKey in (2, 4)
 and a13.IsPreDetermination in (1)
 and a12.AuthReviewUMFinalStatusKey in (3, 5, 4)
 and a12.AuthReviewTypeKey in (1)
 and a14.CLIENT_ID in (@ClientID)
 and a14.LOB_CODE in (@LobCode)
 and a15.DATE between @StartDate and @EndDate
 and a11.DenialText is not null)

create table ##TPX4CBUG7MD007(
	ReviewReceivedDateDimKey	BIGINT, 
	Review_Priority_Key	TINYINT, 
	Reference_Number	VARCHAR(50), 
	LOB_CODE	VARCHAR(5), 
	LOB_DESC	VARCHAR(50), 
	Denial_Reason_Key	INTEGER, 
	Review_Status_Key	TINYINT, 
	DATE_DIM_KEY	BIGINT, 
	DATE0	DATE, 
	CLIENT_ID	INTEGER, 
	IDTSWITHDENIALDETAILS	NVARCHAR(2000))

insert into ##TPX4CBUG7MD007 (ReviewReceivedDateDimKey, Review_Priority_Key, Reference_Number, LOB_CODE, LOB_DESC, Denial_Reason_Key, Review_Status_Key, DATE_DIM_KEY, DATE0, CLIENT_ID, IDTSWITHDENIALDETAILS)
select	ReviewReceivedDateDimKey
	,	Review_Priority_Key
	,	Reference_Number
	,	LOB_CODE
	,	LOB_DESC
	,	Denial_Reason_Key
	,	Review_Status_Key
	,	DATE_DIM_KEY
	,	DATE0
	,	CLIENT_ID
	,	LEFT(STUFF((SELECT ', ' + WJXBFS1
					FROM #denial_texts dt1
					WHERE	dt1.Reference_Number = dt2.Reference_Number
						AND	dt1.Review_Status_Key = dt2.Review_Status_Key
						AND	dt1.ReviewReceivedDateDimKey = dt2.ReviewReceivedDateDimKey
						AND dt1.DATE_DIM_KEY = dt2.DATE_DIM_KEY
						AND dt1.Denial_Reason_Key = dt2.Denial_Reason_Key
					FOR XML PATH('')),1,1,''), 2000)
from	#denial_texts dt2

select	distinct coalesce(pa11.FIRST_NAME, pa13.FIRST_NAME, pa14.FIRST_NAME, pa16.FIRST_NAME, pa17.FIRST_NAME)  FIRST_NAME,
	coalesce(pa11.CustCol_309, pa13.CustCol_309, pa14.CustCol_309, pa16.CustCol_309, pa17.CustCol_309)  CustCol_309,
	coalesce(pa11.LAST_NAME, pa13.LAST_NAME, pa14.LAST_NAME, pa16.LAST_NAME, pa17.LAST_NAME)  LAST_NAME,
	coalesce(pa11.CustCol_310, pa13.CustCol_310, pa14.CustCol_310, pa16.CustCol_310, pa17.CustCol_310)  CustCol_310,
	coalesce(pa11.CustCol_305, pa13.CustCol_305, pa14.CustCol_305, pa16.CustCol_305, pa17.CustCol_305)  CustCol_305,
	coalesce(pa11.CustCol_306, pa13.CustCol_306, pa14.CustCol_306, pa16.CustCol_306, pa17.CustCol_306)  CustCol_306,
	coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID, pa13.CLIENT_ID, pa14.CLIENT_ID, pa16.CLIENT_ID, pa17.CLIENT_ID, pa18.CLIENT_ID, pa19.CLIENT_ID)  CLIENT_ID,
	a110.CLIENT_NAME  CLIENT_NAME,
	coalesce(pa11.LOB_CODE, pa12.LOB_CODE, pa13.LOB_CODE, pa14.LOB_CODE, pa16.LOB_CODE, pa17.LOB_CODE, pa18.LOB_CODE, pa19.LOB_CODE)  LOB_CODE,
	coalesce(pa11.LOB_DESC, pa12.LOB_DESC, pa13.LOB_DESC, pa14.LOB_DESC, pa16.LOB_DESC, pa17.LOB_DESC, pa18.LOB_DESC, pa19.LOB_DESC)  LOB_DESC,
	coalesce(pa11.Auth_Type_Key, pa13.Auth_Type_Key, pa14.Auth_Type_Key, pa16.Auth_Type_Key, pa17.Auth_Type_Key)  Auth_Type_Key,
	a114.Auth_Type_Desc  Auth_Type_Desc,
	coalesce(pa11.Requestor_Type_Key, pa13.Requestor_Type_Key, pa14.Requestor_Type_Key, pa16.Requestor_Type_Key, pa17.Requestor_Type_Key)  Requestor_Type_Key,
	a115.Requestor_Type_Desc  Requestor_Type_Desc,
	coalesce(pa11.Place_of_Service_Key, pa12.Place_of_Service_Key, pa13.Place_of_Service_Key, pa14.Place_of_Service_Key, pa16.Place_of_Service_Key, pa17.Place_of_Service_Key)  Place_of_Service_Key,
	a113.Place_Of_Service_Desc  Place_Of_Service_Desc,
	coalesce(pa11.Reference_Number, pa12.Reference_Number, pa13.Reference_Number, pa14.Reference_Number, pa16.Reference_Number, pa17.Reference_Number, pa18.Reference_Number, pa19.Reference_Number)  Reference_Number,
	coalesce(pa11.IsPreDetermination, pa13.IsPreDetermination, pa14.IsPreDetermination, pa16.IsPreDetermination, pa17.IsPreDetermination)  IsPreDetermination,
	a112.YesNoDesc  YesNoDesc,
	coalesce(pa11.CustCol_142, pa13.CustCol_142, pa14.CustCol_142, pa16.CustCol_142, pa17.CustCol_142)  CustCol_142,
	coalesce(pa11.Review_Type_Key, pa16.Review_Type_Key)  Review_Type_Key,
	a118.Review_Type_Desc  Review_Type_Desc,
	coalesce(pa11.CustCol_322, pa16.CustCol_322)  CustCol_322,
	coalesce(pa11.If_Extension_was_Taken_Did_Sponsor, pa16.If_Extension_was_Taken_Did_Sponsor)  If_Extension_was_Taken_Did_Sponsor,
	coalesce(pa11.Was_A_Timeframe_Extension_Taken, pa16.Was_A_Timeframe_Extension_Taken)  Was_A_Timeframe_Extension_Taken,
	coalesce(pa11.Denied_For_Lack_Of_Medical_Necessity, pa16.Denied_For_Lack_Of_Medical_Necessity)  Denied_For_Lack_Of_Medical_Necessity,
	coalesce(pa11.Review_Status_Key, pa13.Review_Status_Key, pa16.Review_Status_Key, pa17.Review_Status_Key, pa18.Review_Status_Key, pa19.Review_Status_Key)  Review_Status_Key,
	a111.Review_Status_Desc  Review_Status_Desc,
	coalesce(pa11.ReviewReceivedDateDimKey, pa13.ReviewReceivedDateDimKey, pa14.ReviewReceivedDateDimKey, pa16.ReviewReceivedDateDimKey, pa17.ReviewReceivedDateDimKey, pa18.ReviewReceivedDateDimKey, pa19.ReviewReceivedDateDimKey)  ReviewReceivedDateDimKey,
	a117.DATE  DATE,
	coalesce(pa11.DATE_DIM_KEY, pa12.DATE_DIM_KEY, pa13.DATE_DIM_KEY, pa14.DATE_DIM_KEY, pa16.DATE_DIM_KEY, pa17.DATE_DIM_KEY, pa18.DATE_DIM_KEY, pa19.DATE_DIM_KEY)  DATE_DIM_KEY,
	coalesce(pa11.DATE0, pa12.DATE, pa13.DATE0, pa14.DATE0, pa16.DATE0, pa17.DATE0, pa18.DATE0, pa19.DATE0)  DATE0,
	coalesce(pa11.DATE_SERVICE_AUTH_IN_SPON_SYS, pa13.DATE_SERVICE_AUTH_IN_SPON_SYS, pa14.DATE_SERVICE_AUTH_IN_SPON_SYS, pa16.DATE_SERVICE_AUTH_IN_SPON_SYS, pa17.DATE_SERVICE_AUTH_IN_SPON_SYS)  DATE_SERVICE_AUTH_IN_SPON_SYS,
	coalesce(pa11.Denial_Reason_Key, pa16.Denial_Reason_Key, pa18.Denial_Reason_Key, pa19.Denial_Reason_Key)  Denial_Reason_Key,
	pa11.Denial_Reason_Desc  Denial_Reason_Desc,
	coalesce(pa11.Review_Priority_Key, pa16.Review_Priority_Key, pa18.Review_Priority_Key, pa19.Review_Priority_Key)  Review_Priority_Key,
	a116.Review_Priority_Desc  Review_Priority_Desc,
	coalesce(pa11.Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe, pa16.Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe)  Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe,
	coalesce(pa11.MEMBER_NBR, pa13.MEMBER_NBR, pa14.MEMBER_NBR, pa16.MEMBER_NBR, pa17.MEMBER_NBR)  MEMBER_NBR,
	pa12.FINALDIAGNOSISFORAUTHREQ  FINALDIAGNOSISFORAUTHREQ,
	pa13.DATEOFORALNOTIFICATION  DATEOFORALNOTIFICATION,
	pa14.AORRECEIPTDATEREVIEWLEVEL  AORRECEIPTDATEREVIEWLEVEL,
	pa14.AORRECEIPTDATEREQUESTLEVEL  AORRECEIPTDATEREQUESTLEVEL,
	pa11.IDTSWITHDENIALREASON  IDTSWITHDENIALREASON,
	pa16.MAILSUCCESSDATE  MAILSUCCESSDATE,
	pa17.FIRSTPRINTDATE  FIRSTPRINTDATE,
	pa16.WJXBFS1  WJXBFS1,
	pa17.WJXBFS1  WJXBFS2,
	pa18.IDTSWITHPROCDESC  IDTSWITHPROCDESC,
	pa18.IDTSWITHPROCDESCFORDENIALS  IDTSWITHPROCDESCFORDENIALS,
	pa19.IDTSWITHDENIALDETAILS  IDTSWITHDENIALDETAILS
into	#final_pass
from	##TWPKGGT6VMD003	pa11
	full outer join	##THK5BKU6VMD000	pa12
	  on 	(pa11.CLIENT_ID = pa12.CLIENT_ID and 
	pa11.DATE_DIM_KEY = pa12.DATE_DIM_KEY and 
	pa11.LOB_CODE = pa12.LOB_CODE and 
	pa11.Place_of_Service_Key = pa12.Place_of_Service_Key and 
	pa11.Reference_Number = pa12.Reference_Number)
	full outer join	##T207JC9P3MD001	pa13
	  on 	(coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID) = pa13.CLIENT_ID and 
	coalesce(pa11.DATE_DIM_KEY, pa12.DATE_DIM_KEY) = pa13.DATE_DIM_KEY and 
	coalesce(pa11.LOB_CODE, pa12.LOB_CODE) = pa13.LOB_CODE and 
	coalesce(pa11.Place_of_Service_Key, pa12.Place_of_Service_Key) = pa13.Place_of_Service_Key and 
	coalesce(pa11.Reference_Number, pa12.Reference_Number) = pa13.Reference_Number and 
	pa11.Auth_Type_Key = pa13.Auth_Type_Key and 
	pa11.CustCol_142 = pa13.CustCol_142 and 
	pa11.CustCol_305 = pa13.CustCol_305 and 
	pa11.CustCol_306 = pa13.CustCol_306 and 
	pa11.DATE_SERVICE_AUTH_IN_SPON_SYS = pa13.DATE_SERVICE_AUTH_IN_SPON_SYS and 
	pa11.FIRST_NAME = pa13.FIRST_NAME and 
	pa11.IsPreDetermination = pa13.IsPreDetermination and 
	pa11.LAST_NAME = pa13.LAST_NAME and 
	pa11.MEMBER_NBR = pa13.MEMBER_NBR and 
	pa11.Requestor_Type_Key = pa13.Requestor_Type_Key and 
	pa11.ReviewReceivedDateDimKey = pa13.ReviewReceivedDateDimKey and 
	pa11.Review_Status_Key = pa13.Review_Status_Key)
	full outer join	##TO64DK9EFMD002	pa14
	  on 	(coalesce(pa11.Auth_Type_Key, pa13.Auth_Type_Key) = pa14.Auth_Type_Key and 
	coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID, pa13.CLIENT_ID) = pa14.CLIENT_ID and 
	coalesce(pa11.CustCol_142, pa13.CustCol_142) = pa14.CustCol_142 and 
	coalesce(pa11.CustCol_305, pa13.CustCol_305) = pa14.CustCol_305 and 
	coalesce(pa11.CustCol_306, pa13.CustCol_306) = pa14.CustCol_306 and 
	coalesce(pa11.DATE_DIM_KEY, pa12.DATE_DIM_KEY, pa13.DATE_DIM_KEY) = pa14.DATE_DIM_KEY and 
	coalesce(pa11.DATE_SERVICE_AUTH_IN_SPON_SYS, pa13.DATE_SERVICE_AUTH_IN_SPON_SYS) = pa14.DATE_SERVICE_AUTH_IN_SPON_SYS and 
	coalesce(pa11.FIRST_NAME, pa13.FIRST_NAME) = pa14.FIRST_NAME and 
	coalesce(pa11.IsPreDetermination, pa13.IsPreDetermination) = pa14.IsPreDetermination and 
	coalesce(pa11.LAST_NAME, pa13.LAST_NAME) = pa14.LAST_NAME and 
	coalesce(pa11.LOB_CODE, pa12.LOB_CODE, pa13.LOB_CODE) = pa14.LOB_CODE and 
	coalesce(pa11.MEMBER_NBR, pa13.MEMBER_NBR) = pa14.MEMBER_NBR and 
	coalesce(pa11.Place_of_Service_Key, pa12.Place_of_Service_Key, pa13.Place_of_Service_Key) = pa14.Place_of_Service_Key and 
	coalesce(pa11.Reference_Number, pa12.Reference_Number, pa13.Reference_Number) = pa14.Reference_Number and 
	coalesce(pa11.Requestor_Type_Key, pa13.Requestor_Type_Key) = pa14.Requestor_Type_Key and 
	coalesce(pa11.ReviewReceivedDateDimKey, pa13.ReviewReceivedDateDimKey) = pa14.ReviewReceivedDateDimKey)
	full outer join	##TXPYCNDTZMD004	pa16
	  on 	(coalesce(pa11.Auth_Type_Key, pa13.Auth_Type_Key, pa14.Auth_Type_Key) = pa16.Auth_Type_Key and 
	coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID, pa13.CLIENT_ID, pa14.CLIENT_ID) = pa16.CLIENT_ID and 
	coalesce(pa11.CustCol_142, pa13.CustCol_142, pa14.CustCol_142) = pa16.CustCol_142 and 
	coalesce(pa11.CustCol_305, pa13.CustCol_305, pa14.CustCol_305) = pa16.CustCol_305 and 
	coalesce(pa11.CustCol_306, pa13.CustCol_306, pa14.CustCol_306) = pa16.CustCol_306 and 
	coalesce(pa11.DATE_DIM_KEY, pa12.DATE_DIM_KEY, pa13.DATE_DIM_KEY, pa14.DATE_DIM_KEY) = pa16.DATE_DIM_KEY and 
	coalesce(pa11.DATE_SERVICE_AUTH_IN_SPON_SYS, pa13.DATE_SERVICE_AUTH_IN_SPON_SYS, pa14.DATE_SERVICE_AUTH_IN_SPON_SYS) = pa16.DATE_SERVICE_AUTH_IN_SPON_SYS and 
	coalesce(pa11.FIRST_NAME, pa13.FIRST_NAME, pa14.FIRST_NAME) = pa16.FIRST_NAME and 
	coalesce(pa11.IsPreDetermination, pa13.IsPreDetermination, pa14.IsPreDetermination) = pa16.IsPreDetermination and 
	coalesce(pa11.LAST_NAME, pa13.LAST_NAME, pa14.LAST_NAME) = pa16.LAST_NAME and 
	coalesce(pa11.LOB_CODE, pa12.LOB_CODE, pa13.LOB_CODE, pa14.LOB_CODE) = pa16.LOB_CODE and 
	coalesce(pa11.MEMBER_NBR, pa13.MEMBER_NBR, pa14.MEMBER_NBR) = pa16.MEMBER_NBR and 
	coalesce(pa11.Place_of_Service_Key, pa12.Place_of_Service_Key, pa13.Place_of_Service_Key, pa14.Place_of_Service_Key) = pa16.Place_of_Service_Key and 
	coalesce(pa11.Reference_Number, pa12.Reference_Number, pa13.Reference_Number, pa14.Reference_Number) = pa16.Reference_Number and 
	coalesce(pa11.Requestor_Type_Key, pa13.Requestor_Type_Key, pa14.Requestor_Type_Key) = pa16.Requestor_Type_Key and 
	coalesce(pa11.ReviewReceivedDateDimKey, pa13.ReviewReceivedDateDimKey, pa14.ReviewReceivedDateDimKey) = pa16.ReviewReceivedDateDimKey and 
	coalesce(pa11.Review_Status_Key, pa13.Review_Status_Key) = pa16.Review_Status_Key and 
	pa11.CustCol_322 = pa16.CustCol_322 and 
	pa11.Denial_Reason_Key = pa16.Denial_Reason_Key and 
	pa11.Denied_For_Lack_Of_Medical_Necessity = pa16.Denied_For_Lack_Of_Medical_Necessity and 
	pa11.If_Extension_was_Taken_Did_Sponsor = pa16.If_Extension_was_Taken_Did_Sponsor and 
	pa11.Review_Priority_Key = pa16.Review_Priority_Key and 
	pa11.Review_Type_Key = pa16.Review_Type_Key and 
	pa11.Was_A_Timeframe_Extension_Taken = pa16.Was_A_Timeframe_Extension_Taken and 
	pa11.Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe = pa16.Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe)
	full outer join	##TQ98OVEC7MD005	pa17
	  on 	(coalesce(pa11.Auth_Type_Key, pa13.Auth_Type_Key, pa14.Auth_Type_Key, pa16.Auth_Type_Key) = pa17.Auth_Type_Key and 
	coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID, pa13.CLIENT_ID, pa14.CLIENT_ID, pa16.CLIENT_ID) = pa17.CLIENT_ID and 
	coalesce(pa11.CustCol_142, pa13.CustCol_142, pa14.CustCol_142, pa16.CustCol_142) = pa17.CustCol_142 and 
	coalesce(pa11.CustCol_305, pa13.CustCol_305, pa14.CustCol_305, pa16.CustCol_305) = pa17.CustCol_305 and 
	coalesce(pa11.CustCol_306, pa13.CustCol_306, pa14.CustCol_306, pa16.CustCol_306) = pa17.CustCol_306 and 
	coalesce(pa11.DATE_DIM_KEY, pa12.DATE_DIM_KEY, pa13.DATE_DIM_KEY, pa14.DATE_DIM_KEY, pa16.DATE_DIM_KEY) = pa17.DATE_DIM_KEY and 
	coalesce(pa11.DATE_SERVICE_AUTH_IN_SPON_SYS, pa13.DATE_SERVICE_AUTH_IN_SPON_SYS, pa14.DATE_SERVICE_AUTH_IN_SPON_SYS, pa16.DATE_SERVICE_AUTH_IN_SPON_SYS) = pa17.DATE_SERVICE_AUTH_IN_SPON_SYS and 
	coalesce(pa11.FIRST_NAME, pa13.FIRST_NAME, pa14.FIRST_NAME, pa16.FIRST_NAME) = pa17.FIRST_NAME and 
	coalesce(pa11.IsPreDetermination, pa13.IsPreDetermination, pa14.IsPreDetermination, pa16.IsPreDetermination) = pa17.IsPreDetermination and 
	coalesce(pa11.LAST_NAME, pa13.LAST_NAME, pa14.LAST_NAME, pa16.LAST_NAME) = pa17.LAST_NAME and 
	coalesce(pa11.LOB_CODE, pa12.LOB_CODE, pa13.LOB_CODE, pa14.LOB_CODE, pa16.LOB_CODE) = pa17.LOB_CODE and 
	coalesce(pa11.MEMBER_NBR, pa13.MEMBER_NBR, pa14.MEMBER_NBR, pa16.MEMBER_NBR) = pa17.MEMBER_NBR and 
	coalesce(pa11.Place_of_Service_Key, pa12.Place_of_Service_Key, pa13.Place_of_Service_Key, pa14.Place_of_Service_Key, pa16.Place_of_Service_Key) = pa17.Place_of_Service_Key and 
	coalesce(pa11.Reference_Number, pa12.Reference_Number, pa13.Reference_Number, pa14.Reference_Number, pa16.Reference_Number) = pa17.Reference_Number and 
	coalesce(pa11.Requestor_Type_Key, pa13.Requestor_Type_Key, pa14.Requestor_Type_Key, pa16.Requestor_Type_Key) = pa17.Requestor_Type_Key and 
	coalesce(pa11.ReviewReceivedDateDimKey, pa13.ReviewReceivedDateDimKey, pa14.ReviewReceivedDateDimKey, pa16.ReviewReceivedDateDimKey) = pa17.ReviewReceivedDateDimKey and 
	coalesce(pa11.Review_Status_Key, pa13.Review_Status_Key, pa16.Review_Status_Key) = pa17.Review_Status_Key)
	full outer join	##TVEGXHE93MD006	pa18
	  on 	(coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID, pa13.CLIENT_ID, pa14.CLIENT_ID, pa16.CLIENT_ID, pa17.CLIENT_ID) = pa18.CLIENT_ID and 
	coalesce(pa11.DATE_DIM_KEY, pa12.DATE_DIM_KEY, pa13.DATE_DIM_KEY, pa14.DATE_DIM_KEY, pa16.DATE_DIM_KEY, pa17.DATE_DIM_KEY) = pa18.DATE_DIM_KEY and 
	coalesce(pa11.Denial_Reason_Key, pa16.Denial_Reason_Key) = pa18.Denial_Reason_Key and 
	coalesce(pa11.LOB_CODE, pa12.LOB_CODE, pa13.LOB_CODE, pa14.LOB_CODE, pa16.LOB_CODE, pa17.LOB_CODE) = pa18.LOB_CODE and 
	coalesce(pa11.Reference_Number, pa12.Reference_Number, pa13.Reference_Number, pa14.Reference_Number, pa16.Reference_Number, pa17.Reference_Number) = pa18.Reference_Number and 
	coalesce(pa11.ReviewReceivedDateDimKey, pa13.ReviewReceivedDateDimKey, pa14.ReviewReceivedDateDimKey, pa16.ReviewReceivedDateDimKey, pa17.ReviewReceivedDateDimKey) = pa18.ReviewReceivedDateDimKey and 
	coalesce(pa11.Review_Priority_Key, pa16.Review_Priority_Key) = pa18.Review_Priority_Key and 
	coalesce(pa11.Review_Status_Key, pa13.Review_Status_Key, pa16.Review_Status_Key, pa17.Review_Status_Key) = pa18.Review_Status_Key)
	full outer join	##TPX4CBUG7MD007	pa19
	  on 	(coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID, pa13.CLIENT_ID, pa14.CLIENT_ID, pa16.CLIENT_ID, pa17.CLIENT_ID, pa18.CLIENT_ID) = pa19.CLIENT_ID and 
	coalesce(pa11.DATE_DIM_KEY, pa12.DATE_DIM_KEY, pa13.DATE_DIM_KEY, pa14.DATE_DIM_KEY, pa16.DATE_DIM_KEY, pa17.DATE_DIM_KEY, pa18.DATE_DIM_KEY) = pa19.DATE_DIM_KEY and 
	coalesce(pa11.Denial_Reason_Key, pa16.Denial_Reason_Key, pa18.Denial_Reason_Key) = pa19.Denial_Reason_Key and 
	coalesce(pa11.LOB_CODE, pa12.LOB_CODE, pa13.LOB_CODE, pa14.LOB_CODE, pa16.LOB_CODE, pa17.LOB_CODE, pa18.LOB_CODE) = pa19.LOB_CODE and 
	coalesce(pa11.Reference_Number, pa12.Reference_Number, pa13.Reference_Number, pa14.Reference_Number, pa16.Reference_Number, pa17.Reference_Number, pa18.Reference_Number) = pa19.Reference_Number and 
	coalesce(pa11.ReviewReceivedDateDimKey, pa13.ReviewReceivedDateDimKey, pa14.ReviewReceivedDateDimKey, pa16.ReviewReceivedDateDimKey, pa17.ReviewReceivedDateDimKey, pa18.ReviewReceivedDateDimKey) = pa19.ReviewReceivedDateDimKey and 
	coalesce(pa11.Review_Priority_Key, pa16.Review_Priority_Key, pa18.Review_Priority_Key) = pa19.Review_Priority_Key and 
	coalesce(pa11.Review_Status_Key, pa13.Review_Status_Key, pa16.Review_Status_Key, pa17.Review_Status_Key, pa18.Review_Status_Key) = pa19.Review_Status_Key)
	left outer join	CLIENT	a110
	  on 	(coalesce(pa11.CLIENT_ID, pa12.CLIENT_ID, pa13.CLIENT_ID, pa14.CLIENT_ID, pa16.CLIENT_ID, pa17.CLIENT_ID, pa18.CLIENT_ID, pa19.CLIENT_ID) = a110.CLIENT_ID)
	left outer join	VW_Dim_UM_Review_Status	a111
	  on 	(coalesce(pa11.Review_Status_Key, pa13.Review_Status_Key, pa16.Review_Status_Key, pa17.Review_Status_Key, pa18.Review_Status_Key, pa19.Review_Status_Key) = a111.Review_Status_Key)
	left outer join	VW_Dim_UM_YesNo	a112
	  on 	(coalesce(pa11.IsPreDetermination, pa13.IsPreDetermination, pa14.IsPreDetermination, pa16.IsPreDetermination, pa17.IsPreDetermination) = a112.YesNoKey)
	left outer join	VW_Dim_UM_Place_Of_Service	a113
	  on 	(coalesce(pa11.Place_of_Service_Key, pa12.Place_of_Service_Key, pa13.Place_of_Service_Key, pa14.Place_of_Service_Key, pa16.Place_of_Service_Key, pa17.Place_of_Service_Key) = a113.Place_of_Service_Key)
	left outer join	VW_Dim_UM_Auth_Type	a114
	  on 	(coalesce(pa11.Auth_Type_Key, pa13.Auth_Type_Key, pa14.Auth_Type_Key, pa16.Auth_Type_Key, pa17.Auth_Type_Key) = a114.Auth_Type_Key)
	left outer join	VW_Dim_UM_Requestor_Type	a115
	  on 	(coalesce(pa11.Requestor_Type_Key, pa13.Requestor_Type_Key, pa14.Requestor_Type_Key, pa16.Requestor_Type_Key, pa17.Requestor_Type_Key) = a115.Requestor_Type_Key)
	left outer join	VW_Dim_UM_Review_Priority	a116
	  on 	(coalesce(pa11.Review_Priority_Key, pa16.Review_Priority_Key, pa18.Review_Priority_Key, pa19.Review_Priority_Key) = a116.Review_Priority_Key)
	left outer join	DATE_DIM	a117
	  on 	(coalesce(pa11.ReviewReceivedDateDimKey, pa13.ReviewReceivedDateDimKey, pa14.ReviewReceivedDateDimKey, pa16.ReviewReceivedDateDimKey, pa17.ReviewReceivedDateDimKey, pa18.ReviewReceivedDateDimKey, pa19.ReviewReceivedDateDimKey) = a117.DATE_DIM_KEY)
	left outer join	VW_Dim_UM_Review_Type	a118
	  on 	(coalesce(pa11.Review_Type_Key, pa16.Review_Type_Key) = a118.Review_Type_Key)

select	FIRST_NAME AS [Beneficiary First Name]
	,	LAST_NAME AS [Beneficiary Last Name]
	,	MEMBER_NBR AS [Cardholder ID]
	,	CustCol_305 AS [Contract ID]
	,	CustCol_306 AS [Plan ID]
	,	Reference_Number AS [Authorization or Claim Number]
	,	CASE WHEN Requestor_Type_Key = 12 THEN 'CP' WHEN Requestor_Type_Key = 13 THEN 'B' WHEN Requestor_Type_Key = 14 THEN 'BR' WHEN Requestor_Type_Key = 15 THEN 'NCP' END AS [Who made the request]
	,	CASE WHEN CustCol_142 = 'In Network' THEN 'CP' ELSE 'Out of Network' END AS [Provider Type]
	,	DATE AS [Date the request was received]
	,	FINALDIAGNOSISFORAUTHREQ AS [Diagnosis]
	,	LEFT
		(
			CONCAT
			(
				CASE WHEN Place_of_Service_Key = 3 THEN 'Outpatient' ELSE Place_Of_Service_Desc END,
				'-',
				Place_Of_Service_Desc,
				'-',
				CASE WHEN Review_Status_Key = 5 THEN CONCAT('-', IDTSWITHPROCDESCFORDENIALS) ELSE IDTSWITHPROCDESC END,
				'-',
				Review_Status_Desc,
				CASE WHEN Review_Status_Key = 5 AND Denial_Reason_Desc IS NOT NULL THEN CONCAT('-', Denial_Reason_Desc) ELSE '' END,
				CASE WHEN Review_Status_Key = 5 AND IDTSWITHDENIALDETAILS IS NOT NULL THEN CONCAT('-', IDTSWITHDENIALDETAILS) ELSE '' END
			),
			2000
		) AS [Issue Description and Type of Service]
	,	Was_Request_Made_Under_the_Expedited_Timeframe_But_Processed_By_the_Plan_Under_The_Standard_Timeframe AS [Was Request Made Under the Expedited Timeframe But Processed By the Plan Under The Standard Timeframe]
	,	Was_A_Timeframe_Extension_Taken AS [Was a timeframe extension taken]
	,	If_Extension_was_Taken_Did_Sponsor --AS [If extension was taken, did the sponsor notify the member of the reason(s) for the delay and of their right to file an expedited grievance?]
	,	CASE WHEN Review_Status_Key = 3 THEN 'Approved' ELSE 'Denied' END AS [Request Disposition]
	,	DATE0 AS [Date of sponsor decision]
	,	Denied_For_Lack_Of_Medical_Necessity AS [Was the request denied for lack of medical necessity?]
	,	DATEOFORALNOTIFICATION AS [Date oral notification provided to enrollee]
	,	CASE WHEN MAILSUCCESSDATE IS NOT NULL THEN WJXBFS1 ELSE CASE WHEN FIRSTPRINTDATE IS NOT NULL THEN WJXBFS2 ELSE NULL END END AS [Date written notification provided to enrollee]
	,	DATE_SERVICE_AUTH_IN_SPON_SYS AS [Date service authorization entered/effectuated in the sponsor’s system]
	,	CASE WHEN (AORRECEIPTDATEREVIEWLEVEL = '8999-01-01 00:00:00.000' or AORRECEIPTDATEREVIEWLEVEL is null) THEN AORRECEIPTDATEREQUESTLEVEL ELSE AORRECEIPTDATEREVIEWLEVEL END AS [AOR received date]
	,	CustCol_322 AS [First Tier, Downstream, and Related Entity]
	,	DATE_DIM_KEY - ReviewReceivedDateDimKey AS [Turn around time for decision]
	,	CASE WHEN DATE_DIM_KEY - ReviewReceivedDateDimKey <= 14 THEN 'Y' ELSE 'N' END AS [Timeliness of decision]
	,	CASE WHEN MAILSUCCESSDATE IS NOT NULL THEN DATEDIFF(DD, DATE, WJXBFS1) ELSE CASE WHEN FIRSTPRINTDATE IS NOT NULL THEN DATEDIFF(DD, DATE, WJXBFS2) ELSE NULL END END AS [Turn around time for written notification]
	,	CASE
			WHEN MAILSUCCESSDATE IS NOT NULL
				THEN
				CASE
					WHEN DATEDIFF(DD, DATE, WJXBFS1) <= 14
						THEN 'Y'
					ELSE 'N'
				END
			ELSE
			CASE
				WHEN FIRSTPRINTDATE IS NOT NULL
					THEN
					CASE
						WHEN DATEDIFF(DD, DATE, WJXBFS2) <= 14
							THEN 'Y'
						ELSE 'N'
					END
				ELSE 'NA'
			END
		END AS [Timeliness of written notification]
from	#final_pass

drop table ##THK5BKU6VMD000

drop table ##T207JC9P3MD001

drop table ##TO64DK9EFMD002

drop table ##TWPKGGT6VMD003

drop table ##TXPYCNDTZMD004

drop table ##TQ98OVEC7MD005

drop table ##TVEGXHE93MD006

drop table ##TPX4CBUG7MD007

drop table #diagnosis_details

drop table #procedure_details

drop table #denial_texts

drop table #final_pass