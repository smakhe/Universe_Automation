import xlrd
import Common.uni_functions as uf
import datetime
import time
import logging
import pandas as pd

start = time.time()  # Capture the time at the start of the execution
#log_file_path = (uf.create_folder('Logs')+'\\').replace('/', '\\')  # Fodler for Logs
log_file_name = 'Log_U1_' + datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '.log'  # Log Files
for handler in logging.root.handlers[:]:
    logging.root.removeHandler(handler)
logging.basicConfig(filename="D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\U1Logs\\"+log_file_name, level=logging.ERROR,
                    format='%(asctime)s %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p', filemode='w')
logging.error('This tool is Utomation (Universe Reports Automation) created by Madhusudan Dhakite')

f1 = open("D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\Extras\\f1","r")
concat_sql_file2 = open("D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\SQL\\u1_sql_concat2","r")
file_name = "D:\\Users\\MDhakite\\Desktop\\WORK\\Automation\\Universe_2020\\Reports\\U1Report2020.xlsx"
sql_f1 = f1.read()
sql2 = concat_sql_file2.read()
#concat_sql_file1.close()
concat_sql_file2.close()
wb = xlrd.open_workbook(file_name)
sheet = wb.sheet_by_index(0)
logging.error('Reading excel file:'+ file_name)
print('Verifying 22 columns: Beneficiary First Name, Beneficiary Last Name, Enrollee ID, Contract ID ,Plan ID, Authorization or Claim Number, Who made the request?, Provider Type, Date the request was received, Diagnosis, Was request made under the expedited timeframe but processed by the plan under the standard timeframe?, Was a timeframe extension taken?, If an extension was taken, did the sponsor notify the member of the reason(s) for the delay and of their right to file an expedited grievance?, Request Disposition, Date of sponsor decision, Was the request denied for lack of medical necessity?, Date oral notification provided to enrollee, Date service authorization entered/effectuated in the sponsor’s system, AOR receipt date, First Tier, Downstream, and Related Entity, Turn around time for decision, Timeliness for decision \n')
total_reference_numberss = 0
failed_reference_numbers = 0

logging.error('Reaading it row by row')

r = 3

# total_reference_numberss = total_reference_numberss + 1
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
#print(sql_f1)
m = uf.get_db_val(sql_f1 +RefNo + "'")
l1 = m[0]

print(l1)

excel_file = pd.read_excel(file_name, sheet_name=0)

print(excel_file["Authorization or Claim Number"].iloc[3])

#report_list = excel_file[]

#er = excel_file.loc[excel_file['Authorization or Claim Number'] == '7455709']

new_df = pd.read_excel(file_name,sheet_name=0,index_col=5)
print(new_df)

for index, r in new_df.iterrows():
    print(r)

# 1. SQL result --> List : DF
# 2. Excel Row --> List : DF

# 1.