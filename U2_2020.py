import xlrd
import Common.uni_functions as uf
import datetime
import logging
from datetime import time

# start = datetime.time()  # Capture the time at the start of the execution
#log_file_path = (uf.create_folder('Logs')+'\\').replace('/', '\\')  # Fodler for Logs44444444444444444444
log_file_name = 'Log_U2_' + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '.log'  # Log Files
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)
logging.basicConfig(filename="D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\U2Logs\\"+log_file_name, level=logging.ERROR,
                    format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p', filemode='w')
logging.error('This tool is Utomation (Universe Reports Automation) created by Madhusudan Dhakite')

concat_sql_file1 = open("D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\SQL\\u2_sql_concat","r")
concat_sql_file2 = open("D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\SQL\\u2_sql_concat2","r")
file_name = "D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\Reports\\U2Report2020.xlsx"
sql = concat_sql_file1.read()
sql2 = concat_sql_file2.read()
concat_sql_file1.close()
concat_sql_file2.close()
wb = xlrd.open_workbook(file_name)
sheet = wb.sheet_by_index(0)
logging.error('Reading excel file:' + file_name)
print('Verifying 22 columns: Beneficiary First Name, Beneficiary Last Name, Enrollee ID, Contract ID ,Plan ID, Authorization or Claim Number, Who made the request?, Provider Type, Date the request was received, Diagnosis, Was request made under the expedited timeframe but processed by the plan under the standard timeframe?, Was a timeframe extension taken?, If an extension was taken, did the sponsor notify the member of the reason(s) for the delay and of their right to file an expedited grievance?, Request Disposition, Date of sponsor decision, Was the request denied for lack of medical necessity?, Date oral notification provided to enrollee, Date service authorization entered/effectuated in the sponsor’s system, AOR receipt date, First Tier, Downstream, and Related Entity, Turn around time for decision, Timeliness for decision \n')
total_reference_numberss = 0
failed_reference_numbers = 0

logging.error('Reaading it row by row')

for r in range(1, sheet.nrows):
    # print(r)
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
    r_Time_request_received = time(*xlrd.xldate_as_tuple(sheet.cell_value(r, 9), wb.datemode)[3:])  # NEW
    r_diagnosis = sheet.cell_value(r, 10)
    # not considering Issue Description & type of service 11
    r_timeframe_extension = sheet.cell_value(r, 12)
    r_expedited_grievance_col_p = sheet.cell_value(r, 13)
    r_Request_Disposition = sheet.cell_value(r, 14)
    r_Date_sponsor_decision = (datetime.datetime(*xlrd.xldate_as_tuple(sheet.cell_value(r, 15), wb.datemode))).strftime("%Y/%m/%d")
    r_Time_sponsor_decision= time(*xlrd.xldate_as_tuple(sheet.cell_value(r, 16), wb.datemode)[3:])  # NEW
    r_lack_of_medical_necessity = sheet.cell_value(r, 17)
    r_oral_notifiacation = sheet.cell_value(r, 18)
    if sheet.cell_value(r, 19) == 'NA':
        r_time_oral_notifiacation = 'NA'
    else:
        r_time_oral_notifiacation = time(*xlrd.xldate_as_tuple(sheet.cell_value(r, 19), wb.datemode)[3:])  # NEW
    # Not considering Date Written Notification 20 and 21
    if sheet.cell_value(r, 22) == 'NA':
        r_Date_service_authorization = 'NA'
    else:
        r_Date_service_authorization = (datetime.datetime(*xlrd.xldate_as_tuple(sheet.cell_value(r, 22), wb.datemode))).strftime("%Y/%m/%d")

    if sheet.cell_value(r, 23) == 'NA':
        r_Time_service_authorization = 'NA'
    else:
        r_Time_service_authorization = time(*xlrd.xldate_as_tuple(sheet.cell_value(r, 23), wb.datemode)[3:])

    if sheet.cell_value(r, 24) == 'NA':
        r_aor = 'NA'
    else:
        r_aor = (datetime.datetime(*xlrd.xldate_as_tuple(sheet.cell_value(r, 24), wb.datemode))).strftime("%Y/%m/%d")

    if sheet.cell_value(r, 25) == 'NA':
        r_time_aor = 'NA'
    else:
        r_time_aor = time(*xlrd.xldate_as_tuple(sheet.cell_value(r, 25), wb.datemode)[3:])

    r_First_Tier_Related_Entity = sheet.cell_value(r, 26)
    if sheet.cell_value(r, 27) == 'NA':
        r_TAT_for_decision = 'NA'
    else:
        r_TAT_for_decision = int(sheet.cell_value(r, 27))
    r_Timeliness_for_decision = sheet.cell_value(r, 28)

    logging.error('Captured all the values from Excel Report for Reference Number '+str(RefNo))

    # Calculate aor, oral notification date and diagnosis
    aor = uf.u2_calculate_aor(r_Who_made_the_request, RefNo)
    aor_date = aor[0]  # calculate aor value from DB
    aor_time = aor[1]
    oral_notifocation = uf.u2_calculate_oral_notification(r_Request_Disposition, RefNo)
    oral_notification_date = oral_notifocation[0]
    oral_notification_time = oral_notifocation[1]
    diagnosis_calculated = uf.calculate_diagnosis(RefNo)
    logging.error('Calculated required parameters from DB')
    logging.error('AOR Date: '+ aor_date)
    logging.error('AOR Time: '+ aor_time)
    logging.error('Oral Notification Date: ' + oral_notification_date)
    logging.error('Oral Notification Date: ' + oral_notification_time)
    logging.error('Diagnosis Value: '+ diagnosis_calculated)
    # print(oral_notofocation_date)
    logging.error('Comparison with Calculated columns initiated...')
    # Verify hardcoded columns
    if r_First_Tier_Related_Entity != "Evolent Health":
        print('Failure in First Tier, Downstream, and Related Entity column for reference no: ', RefNo)
        print('Expected Value: Evolent Health Actual Value: ', r_First_Tier_Related_Entity)
        logging.error('Failure in First Tier, Downstream, and Related Entity column for reference no: '+ RefNo)
        logging.error('Expected Value: Evolent Health Actual Value: '+ r_First_Tier_Related_Entity)

    # Verify calculated columns
    if r_diagnosis != diagnosis_calculated:
        print('Failure in Diagnosis column for reference no: ', RefNo)
        print('Expected Value: ', diagnosis_calculated, ' Actual Value: ', r_diagnosis)
        logging.error('Failure in Diagnosis column for reference no: '+ str(RefNo))
        logging.error('Expected Value: '+ diagnosis_calculated + ' Actual Value: '+ r_diagnosis)

    if r_aor != aor_date:
        print('Failure in AOR date column for reference no: ', RefNo)
        print('Expected Value: ', aor_date, ' Actual Value: ', r_aor)
        logging.error('Failure in AOR date column for reference no: '+ RefNo)
        logging.error('Expected Value: '+ aor_date + ' Actual Value: '+ r_aor)
    if r_time_aor != aor_time:
        print('Failure in AOR time column for reference no: ', RefNo)
        print('Expected Value: ', aor_time, ' Actual Value: ', r_time_aor)
        logging.error('Failure in AOR time column for reference no: '+ RefNo)
        logging.error('Expected Value: '+ aor_time + ' Actual Value: '+ r_time_aor)

    if oral_notification_date != r_oral_notifiacation:
        print('Failure in Oral Notification Date column for reference no: ', RefNo)
        print('Expected Value: ', oral_notification_date, ' Actual Value: ', r_oral_notifiacation)
        logging.error('Failure in Oral Notification Date column for reference no: '+ RefNo)
        logging.error('Expected Value: '+ oral_notification_date + ' Actual Value: '+ r_oral_notifiacation)
    if oral_notification_time!= r_time_oral_notifiacation:
        print('Failure in Oral Notification Date column for reference no: ', RefNo)
        print('Expected Value: ', oral_notification_time, ' Actual Value: ', r_time_oral_notifiacation)
        logging.error('Failure in Oral Notification Date column for reference no: '+ RefNo)
        logging.error('Expected Value: ' + oral_notification_time + ' Actual Value: '+ r_time_oral_notifiacation)

    logging.error('Comparison with Calculated columns completed.')
    logging.error('Verifying additional columns...')
    # Create SQL string for rest of columns and get values from DB
    logging.error('Constructing sql query for additional columns...')
    extra_sql = "')A where concat(A.FIRST_NAME, A.LAST_NAME, A.MEMBER_NBR, A.CONTRACT_ID, A.PLAN_ID, A.ReferenceNumber,A.RT,A.provider_type,A.date_request_received,A.time_request_received,A.timeframe_extension,A.expedited_grievance_colP,A.Request_Disposition,A.Date_sponsor_decision,A.time_sponsor_decision,A.lack_of_medical_necessity,A.Date_service_authorization,A.Time_service_authorization,A.TAT_for_decision,A.Timeliness_for_decision) in ('"
    # final_str = r_First_Name + r_Last_Name + r_Cardholder_ID + r_Contract_ID + r_Plan_ID + str(RefNo) + r_Who_made_the_request + r_Provider_Type + r_Date_request_received + r_Time_request_received + r_timeframe_extension + r_expedited_grievance_col_p + r_Request_Disposition + r_Date_sponsor_decision + r_Time_sponsor_decision + r_lack_of_medical_necessity + r_Date_service_authorization + r_Time_service_authorization + str(r_TAT_for_decision) + r_Timeliness_for_decision
    final_str = r_First_Name + r_Last_Name + r_Cardholder_ID + r_Contract_ID + r_Plan_ID + \
                str(RefNo) + r_Who_made_the_request + r_Provider_Type + r_Date_request_received + \
                str(r_Time_request_received) + r_timeframe_extension + r_expedited_grievance_col_p + \
                r_Request_Disposition + r_Date_sponsor_decision + str(r_Time_sponsor_decision) + \
                r_lack_of_medical_necessity + r_Date_service_authorization + str(r_Time_service_authorization) + \
                str(r_TAT_for_decision) + r_Timeliness_for_decision
    final_sql = sql + str(RefNo) + "' and md.MEMBER_NBR = '" + r_Cardholder_ID + extra_sql + final_str + "')"
    # logging.error('Sql Query generated...\n' + final_sql)
    logging.error('Extracting records from database...')
    logging.error(final_sql)
    db_records = uf.get_db_val(final_sql)
    logging.error('Validating the records for additional columns...')
    # Verify rest of the columns
    if db_records[0][0] <= 0:
        failed_reference_numbers = failed_reference_numbers + 1
        print('Failure for reference no: ', RefNo)
        logging.error('Failure for reference no: '+ str(RefNo))
        #print(final_sql)
        db_records = uf.get_db_val(sql2 + str(RefNo) + "' and md.MEMBER_NBR = '" + r_Cardholder_ID + "')A")
        logging.error(sql2 + str(RefNo) + "' and md.MEMBER_NBR = '" + r_Cardholder_ID + "')A")
        #print(db_records)
        print('Record from DB: ', db_records[0][0])
        print('Record from Excel Report: ', final_str)
        logging.error('Record from DB: '+ db_records[0][0])
        logging.error('Record from Excel Report: '+ final_str)
    logging.error('No failures in additional columns.')

logging.error('Count of Failed Reference Numbers: '+ str(failed_reference_numbers))
logging.error('Count of Total Reference Numbers: '+ str(total_reference_numberss))

if failed_reference_numbers > 0:
    print('There is mismatch for', failed_reference_numbers, 'Reference Numbers out of', total_reference_numberss, 'Reference Numbers present in the report.')
else:
    print('\nThere is no mismatch, the process ran for ' + str(total_reference_numberss) + ' Reference Numbers')


"""
end = datetime.time()
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
"""

