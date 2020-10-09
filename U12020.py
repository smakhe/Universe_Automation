import xlrd
import uni_functions as uf
import datetime
import time
import logging
import os 
import pandas as pd
import pyodbc
import sqlalchemy as sal
from sqlalchemy import create_engine

#Setting connection string for the database
try:
    server = 'INE1UT-DWDB-001.EHNP.CORP.EVOLENTHEALTH.COM'
    db = 'EVH_DW'
    engine = sal.create_engine('mssql+pyodbc://'+server+'/'+db+'?driver=SQL Server?Trusted_Connection=yes')
    conn = engine.connect()
except:
    print("Database Connection Error!")
    os._exit(1)

#Getting path for the current working directory
dir = os.path.dirname(__file__)


start = time.time()  # Capture the time at the start of the execution
#log_file_path = (uf.create_folder('Logs')+'\\').replace('/', '\\')  # Fodler for Logs
log_file_name = 'Log_U1_' + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '.log'  # Log Files
   
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)
try:
    logging.basicConfig(filename=dir+"\\U1Logs\\"+log_file_name, level=logging.ERROR,
                    format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p', filemode='w')
except:
    logging.error("Cannot open the log file!")

################# Reading Excel into dataframe #################
try:
    print("Fetching data from excel to dataframe")
    logging.error("Fetching data from excel to dataframe")
    univ1_report = dir+"\\Reports\\U1Report2020.xlsx"
    df = pd.read_excel(univ1_report, sheet_name='Sheet1')
    print("Data successfully retrived from excel")
    logging.error("Data successfully retrived from excel")

except:
    print("Cannot open file", univ1_report) 
    os._exit(1)

################# Fetching values from database into dataframe #################
try:
    sql_query = pd.read_sql_query(dir+"\\SQL\\Universe1.sql", engine)
    df_db = pd.DataFrame(sql_query)
    conn.close()
    print(df)
except:
    print("Cannot read from database!") 
    os._exit(1)



concat_sql_file1 = open(dir+"\\SQL\\u1_sql_concat","r")
concat_sql_file2 = open(dir+"\\SQL\\u1_sql_concat2","r")
file_name = dir+"\\Reports\\U1Report2020.xlsx"
sql = concat_sql_file1.read()
sql2 = concat_sql_file2.read()
concat_sql_file1.close()
concat_sql_file2.close()
wb = xlrd.open_workbook(file_name)
sheet = wb.sheet_by_index(0)
logging.error('Reading excel file: '+ file_name + '. One row at a time')
print('Verifying 22 columns: Beneficiary First Name, Beneficiary Last Name, Enrollee ID, Contract ID ,Plan ID, Authorization or Claim Number, Who made the request?, Provider Type, Date the request was received, Diagnosis, Was request made under the expedited timeframe but processed by the plan under the standard timeframe?, Was a timeframe extension taken?, If an extension was taken, did the sponsor notify the member of the reason(s) for the delay and of their right to file an expedited grievance?, Request Disposition, Date of sponsor decision, Was the request denied for lack of medical necessity?, Date oral notification provided to enrollee, Date service authorization entered/effectuated in the sponsor’s system, AOR receipt date, First Tier, Downstream, and Related Entity, Turn around time for decision, Timeliness for decision \n')
total_reference_numberss = 0
failed_reference_numbers = 0

#logging.error('Reading it row by row')

for r in range(1, sheet.nrows):

    total_reference_numberss = total_reference_numberss + 1
    # Get all values from Excel Report
    r_First_Name = sheet.cell_value(r, 0)
    r_Last_Name = sheet.cell_value(r, 1)
    r_Cardholder_ID = sheet.cell_value(r, 2)
    r_Contract_ID = sheet.cell_value(r, 3)
    r_Plan_ID = sheet.cell_value(r, 4)
    RefNo = sheet.cell_value(r, 5)
    r_Who_made_the_request = sheet.cell_value(r, 6)
    r_Provider_Type = sheet.cell_value(r, 7)
    r_Date_request_received = (datetime.datetime(*xlrd.xldate_as_tuple(sheet.cell_value(r, 8), wb.datemode))).strftime("%Y/%m/%d")
    r_diagnosis = sheet.cell_value(r, 9)
    # not considering Issue Description & type of service
    r_request_processed_by_standard_timeframe = sheet.cell_value(r, 11)
    r_timeframe_extension = sheet.cell_value(r, 12)
    r_expedited_grievance_col_p = sheet.cell_value(r, 13)
    r_Request_Disposition = sheet.cell_value(r, 14)
    r_Date_sponsor_decision = (datetime.datetime(*xlrd.xldate_as_tuple(sheet.cell_value(r, 15), wb.datemode))).strftime("%Y/%m/%d")
    r_lack_of_medical_necessity = sheet.cell_value(r, 16)
    r_oral_notifiacation = sheet.cell_value(r, 17)
    # Not considering Date Written Notification 18
    if sheet.cell_value(r, 19) == 'NA':
        r_Date_service_authorization = 'NA'
    else:
        r_Date_service_authorization = (datetime.datetime(*xlrd.xldate_as_tuple(sheet.cell_value(r, 19), wb.datemode))).strftime("%Y/%m/%d")
    if sheet.cell_value(r, 20) == 'NA':
        r_aor = 'NA'
    else:
        r_aor = (datetime.datetime(*xlrd.xldate_as_tuple(sheet.cell_value(r, 20), wb.datemode))).strftime("%Y/%m/%d")

    r_First_Tier_Related_Entity = sheet.cell_value(r, 21)
    if sheet.cell_value(r, 22) == 'NA':
        r_TAT_for_decision = 'NA'
    else:
        r_TAT_for_decision = int(sheet.cell_value(r, 22))
    r_Timeliness_for_decision = sheet.cell_value(r, 23)

    logging.error('Captured all the values from Excel Report for Reference Number '+ str(int(RefNo)))

    # Calculate aor, oral notification date and diagnosis
    aor_date = uf.calculate_aor(r_Who_made_the_request, RefNo)  # calculate aor value from DB
    oral_notofocation_date = uf.calculate_oral_notification(r_Request_Disposition, RefNo)
    diagnosis_calculated = uf.calculate_diagnosis(RefNo)
    logging.error('Calculated required parameters from DB')
    logging.error('AOR Date: '+ aor_date)
    logging.error('Oral Notification Date: '+ oral_notofocation_date)
    logging.error('Diagnosis Value: '+ diagnosis_calculated)
    # print(oral_notofocation_date)
    # Create SQL string for rest of columns and get values from DB
    extra_sql = "')A where concat(A.FIRST_NAME, A.LAST_NAME, A.MEMBER_NBR, A.CONTRACT_ID, A.PLAN_ID, A.ReferenceNumber,A.RT,A.provider_type,A.date_request_received,A.timeframe_extension,A.expedited_grievance_colP,A.Request_Disposition,A.Date_sponsor_decision,A.lack_of_medical_necessity,A.Date_service_authorization,A.TAT_for_decision,A.Timeliness_for_decision) in ('"
    final_str = r_First_Name + r_Last_Name + r_Cardholder_ID + r_Contract_ID + r_Plan_ID + str(RefNo) + \
                r_Who_made_the_request + r_Provider_Type + r_Date_request_received + r_timeframe_extension + \
                r_expedited_grievance_col_p + r_Request_Disposition + r_Date_sponsor_decision + \
                r_lack_of_medical_necessity + r_Date_service_authorization + str(r_TAT_for_decision)+ \
                r_Timeliness_for_decision
    final_sql = sql + str(RefNo)+ "' and md.MEMBER_NBR = '" + r_Cardholder_ID + extra_sql + final_str + "')"
    #logging.error('Sql Query generated...\n' + final_sql)
    db_records = uf.get_db_val(final_sql)
    logging.error('Comparison with Calculated columns initiated...')
    # Verify hardcoded columns
    if r_First_Tier_Related_Entity != "Evolent Health":
        print('Failure in First Tier, Downstream, and Related Entity column for reference no: ', RefNo)
        print('Expected Value: Evolent Health Actual Value: ', r_First_Tier_Related_Entity)
        logging.error('Failure in First Tier, Downstream, and Related Entity column for reference no: '+ RefNo)
        logging.error('Expected Value: Evolent Health Actual Value: '+ r_First_Tier_Related_Entity)
    if r_request_processed_by_standard_timeframe != "N":
        print('Failure in Was request made under the expedited timeframe but processed by the plan under the standard timeframe? column for reference no: ', RefNo)
        print('Expected Value: N Actual Value: ', r_request_processed_by_standard_timeframe)
        logging.error('Failure in Was request made under the expedited timeframe but processed by the plan under the standard timeframe? column for reference no: '+RefNo)
        logging.error('Expected Value: N Actual Value: '+ r_request_processed_by_standard_timeframe)

    # Verify calculated columns
    if r_diagnosis != diagnosis_calculated:
        print('Failure in Diagnosis column for reference no: ', RefNo)
        print('Expected Value: ', diagnosis_calculated, ' Actual Value: ', r_diagnosis)
        logging.error('Failure in Diagnosis column for reference no: '+ RefNo)
        logging.error('Expected Value: '+ diagnosis_calculated + ' Actual Value: '+ r_diagnosis)

    if r_aor != aor_date:
        print('Failure in AOR date column for reference no: ', RefNo)
        print('Expected Value: ', aor_date, ' Actual Value: ', r_aor)
        logging.error('Failure in AOR date column for reference no: '+ RefNo)
        logging.error('Expected Value: '+ aor_date + ' Actual Value: '+ r_aor)

    if oral_notofocation_date != r_oral_notifiacation:
        print('Failure in Oral Notification Date column for reference no: ', RefNo)
        print('Expected Value: ', oral_notofocation_date, ' Actual Value: ', r_oral_notifiacation)
        logging.error('Failure in Oral Notification Date column for reference no: '+ RefNo)
        logging.error('Expected Value: '+ oral_notofocation_date + ' Actual Value: '+ r_oral_notifiacation)

    logging.error('Comparison with Calculated columns completed.')
    logging.error('Verifying additional columns...')
    # Verify rest of the columns
    if db_records[0][0] <= 0:
        failed_reference_numbers = failed_reference_numbers + 1
        print('Failure for reference no: ', RefNo)
        logging.error('Failure for reference no: '+ RefNo)
        #print(final_sql)
        db_records = uf.get_db_val(sql2 + str(RefNo) + "' and md.MEMBER_NBR = '" + r_Cardholder_ID + "')A")
        print('Record from DB: ', db_records[0][0])
        print('Record from Excel Report: ', final_str)
        logging.error('Record from DB: '+ db_records[0][0])
        logging.error('Record from Excel Report: '+ final_str)
    logging.error('No failures in additional columns.')

end = time.time()
hours, rem = divmod(end - start, 3600)
minutes, seconds = divmod(rem, 60)
logging.error('Count of Failed Reference Numbers: '+ str(failed_reference_numbers))
logging.error('Count of Total Reference Numbers: '+ str(total_reference_numberss))
logging.error('Time taken for the process: '+"{:0>2}:{:0>2}:{:05.2f}".format(int(hours), int(minutes), seconds))
if failed_reference_numbers > 0:
    print('There is mismatch for', failed_reference_numbers, 'Reference Numbers out of', total_reference_numberss, 'Reference Numbers present in the report.')
    print('\nThe process ran for ' + str(total_reference_numberss) + ' Reference Numbers in ' +
          "{:0>2}:{:0>2}:{:05.2f}".format(int(hours), int(minutes), seconds))
else:
    print('\nThere is no mismatch, the process ran for ' + str(total_reference_numberss) + ' Reference Numbers in ' +
          "{:0>2}:{:0>2}:{:05.2f}".format(int(hours), int(minutes), seconds))

