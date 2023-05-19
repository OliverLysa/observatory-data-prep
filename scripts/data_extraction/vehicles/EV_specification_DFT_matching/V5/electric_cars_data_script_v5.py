import multiprocessing
import os
import csv
import warnings

warnings.simplefilter(action='ignore', category=FutureWarning)
warnings.simplefilter(action='ignore', category=DeprecationWarning)
from bs4 import BeautifulSoup  # library to parse HTML documents
import json
import re
import requests
import traceback
from datetime import datetime
import pandas as pd

# special option to avoid false positive: this words will be added to the comparation
whitelist = ['recharge', 'electro', 'electric', 'e-tron']

# blacklist: words and symbols to ignore.Should be lowercased
blacklist = ['s-a', '!', ':', '-', '_', '–', '|', '#', 'quattro', 'sportback', 'quattro auto', '4matic', 'awd',
             'x-drive', 'edition 1', 's line', 'tfsi', 'tdi', 'mhev']

# please set this value to True if you want to update the first data source file cars.csv
update_evspecifications = False

# URL of the UK GOV data
data_source_url = 'https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/1077524/df_VEH0124.csv'

# output file name
output_file_name = 'output_v5.csv'

# list of columns to add to the output df. Please be careful with column names.
columns_to_add = ['Electric motor_Electric motor type', 'Electric motor_Location of the motor', 'Electric motor_Power',
                  'Electric motor_Torque', 'Second electric motor_Motor type', 'Second electric motor_Location',
                  'Second electric motor_Power', 'Second electric motor_Torque',
                  'Second electric motor_Regenerative braking']

# please sett to True if you need to save 'matched' values only
save_matched_only = True


def save_csv(data, filename):
    """
    :param csv_inputs:
    :return:
    """
    try:
        with open(filename, "w", encoding='utf-8', newline='') as f:
            writer = csv.writer(f)
            writer.writerows(data)
    except Exception as e:
        print(str(e))
        print("File {} not found or format is wrong".format(filename))


def get_gov_data(data_source_url):
    """
    Downloads UK gov.data by the link and returns as a list of lists
    :return:
    """
    try:
        print_log("Downloading UK gov. data...")
        response = requests.get(data_source_url)
        gov_data_list = list(csv.reader(response.content.decode('latin1').splitlines(), delimiter=','))
        print_log("UK gov. data downloaded: {} lines".format(len(gov_data_list)))
        return gov_data_list
    except Exception as e:
        print_log("Exception in get_gov_data {}".format(str(e)))
        print_log(traceback.format_exc())


def get_brands(headers):
    """
    :return:
    """
    try:

        while True:
            try:

                response = requests.get("https://www.evspecifications.com/", headers=headers)
                if response.status_code == 200:
                    break

            except:
                pass

        brands = []
        html = response.text
        soup = BeautifulSoup(html, "html.parser")

        for brand in soup.find("div", {"class": "brand-listing-container-frontpage"}).find_all("a"):
            brand_name = brand.text
            brand_url = brand["href"]
            print(" " + brand_name + " : " + brand_url)
            brands.append([brand_name, brand_url])

        return brands
    except Exception as e:
        print_log("Exception in get_brands {}".format(str(e)))
        print_log(traceback.format_exc())


def get_models(brand, headers):
    """
    :param brand:
    :return:
    """
    try:
        while True:
            try:

                response = requests.get(brand[1], headers=headers)
                if response.status_code == 200:
                    break

            except:
                pass

        html = response.text
        soup = BeautifulSoup(html, "html.parser")

        regex = re.compile("model_.*")

        models = []
        for model in soup.find_all("div", {"id": regex}):
            model_url = model.find("a")["href"]
            models.append([brand[0], brand[1], model_url])

        return models
    except Exception as e:
        print_log("Exception in get_models {}".format(str(e)))
        print_log(traceback.format_exc())


def fetch_model(model, headers):
    """
    :param model:
    :return:
    """
    try:
        while True:
            try:

                response = requests.get(model[2], headers=headers)
                if response.status_code == 200:
                    break

            except:
                pass

        html = response.text
        soup = BeautifulSoup(html, "html.parser")

        model_name = soup.find("h1").text.split("- Specifications")[0].strip()
        car_image = soup.find("div", {"id": "model-image"})["style"].split("url(")[1].split(");")[0]

        car_details = {

            "Brand Name": model[0],
            "Brand URL": model[1],
            "Model Name": model_name,
            "Model URL": model[2],
            "Car Image": car_image

        }
        brief_specifications = soup.find("div", {"id": "model-brief-specifications"}).find_all("b")

        for specification in brief_specifications:

            specification_key = specification.text.strip()
            specification_value = specification.next.next.strip().split(":")[1].strip()

            if specification_value[-1] == ",":
                specification_value = specification_value[:-1]

            if specification_key in car_details:
                specification_key = specification_key + "_2"

            car_details[specification_key] = specification_value

        tables = soup.find_all("table", {"class": "model-information-table row-selection"})

        headers_list = [
            "Brand, model, trim, price",
            "Body style, dimensions, volumes, weights.",
            "Electric motor",
            "Second electric motor",
            "Performance",
            "Steering",
            "Transmission",
            "Suspension",
            "Brakes",
            "Battery",

        ]
        for table in tables:

            header = table.find_previous("header").find("h2").text.strip()
            if header in headers_list:
                for tr in table.find_all("tr"):
                    specification_key = header + "_" + tr.find_all("td")[0].find("p").previous.strip()
                    specification_value = tr.find_all("td")[1].text.strip()
                    car_details[specification_key] = specification_value

        return car_details
    except Exception as e:
        print_log("Exception in fetch_model {}".format(str(e)))
        print_log(traceback.format_exc())


def update_evspecifications_data():
    """
    updates evspecifications data an saves to cars.csv
    :return:
    """
    try:
        print_log("Updating evspecifications data (cars.csv)...")
        headers = {
            'accept': 'application/json, text/plain, */*',
            'accept-language': 'en-US,en;q=0.9,ar-TN;q=0.8,ar;q=0.7',
            'cache-control': 'no-cache',
            'origin': 'https://www.evspecifications.com/',
            'pragma': 'no-cache',
            'referer': 'https://www.evspecifications.com/',
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36',
        }
        brands = get_brands(headers)
        cars = []
        for brand in brands:

            models = get_models(brand, headers)
            for model in models:
                car_details = fetch_model(model, headers)
                print(car_details)
                cars.append(car_details)
        keys = [i for s in [d.keys() for d in cars] for i in s]
        with open("cars.json", 'w', encoding='utf-8') as outfile:
            json.dump(cars, outfile, sort_keys=False, indent=4, ensure_ascii=False)
        df = pd.read_json("cars.json")
        df.to_csv("cars.csv", index=None)
    except Exception as e:
        print_log("Exception in update_evspecifications_data {}".format(str(e)))
        print_log(traceback.format_exc())


def print_log(msg: str):
    """
    print message and wries to LOG.txt
    :param msg:
    :return:
    """
    try:
        print(msg)
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open("LOG.txt", 'a+', encoding='utf-8') as f:
            f.write('[{}] {}\n'.format(now, msg))
    except Exception as e:
        print(traceback.format_exc())


def create_tricky_model(x):
    result = x['tricky_model'].split()[0] + ''.join(
        [element for element in x['tricky_model'].split()[1:] if element.isnumeric() or element[0] in ['e', 'i'] or element in whitelist])
    return result


def main():
    """
    the main pileline
    :return:
    """
    try:
        # removing LOG file of previous session if exists.
        if os.path.exists("LOG.txt"):
            os.remove("LOG.txt")

        # getting the UK gov data
        gov_data = get_gov_data(data_source_url)
        # saving to csv
        save_csv(gov_data, 'gov_data.csv')
        gov_data_df = pd.read_csv('gov_data.csv')

        print(gov_data_df)
        # getting the first data source data if  specified
        if update_evspecifications:
            update_evspecifications_data()
        cars_data_df = pd.read_csv('cars.csv')

        cars_data_df['tricky_model'] = cars_data_df['Brand, model, trim, price_Model'].astype(str).str.lower()
        cars_data_df['tricky_model'] = cars_data_df.apply(create_tricky_model, axis=1)

        # creating a special key to merge df's case insensitive
        cars_data_df['cars_key'] = cars_data_df['Brand, model, trim, price_Model year'].astype(str).str.lower() + ' ' + \
                                   cars_data_df[
                                       'Brand, model, trim, price_Brand'].astype(str).str.lower() + ' ' + cars_data_df[
                                       'tricky_model'].astype(str).str.lower()

        cars_data_df = cars_data_df.drop('tricky_model', axis=1)

        for blacklist_symbol in blacklist:
            cars_data_df['cars_key'] = cars_data_df['cars_key'].astype(str).str.replace(blacklist_symbol, '')

        cars_data_df['cars_key'] = cars_data_df['cars_key'].astype(str).str.replace(' ', '')

        columns_to_add.append('cars_key')
        # filtering columns to add
        cars_data_df = cars_data_df[columns_to_add]

        gov_data_df['tricky_model'] = gov_data_df['Model'].astype(str).str.lower()
        gov_data_df['tricky_model'] = gov_data_df.apply(create_tricky_model, axis=1)

        # creating a special key to merge df's case insensitive
        gov_data_df['gov_key'] = gov_data_df['YearFirstUsed'].astype(str).str.lower() + ' ' + gov_data_df[
            'Make'].astype(str).str.lower() + ' ' + gov_data_df['tricky_model'].astype(str).str.lower()

        for blacklist_symbol in blacklist:
            gov_data_df['gov_key'] = gov_data_df['gov_key'].astype(str).str.replace(blacklist_symbol, '')
        gov_data_df['gov_key'] = gov_data_df['gov_key'].astype(str).str.replace(' ', '')

        gov_data_df = gov_data_df.drop('tricky_model', axis=1)

        if save_matched_only:
            mode = 'inner'
        else:
            mode = 'left'
        # joining DF's
        result_df = gov_data_df.merge(cars_data_df, left_on='gov_key', right_on='cars_key', how=mode,
                                      indicator=False)
        # removing key rows
        result_df = result_df.drop('gov_key', axis=1)
        result_df = result_df.drop('cars_key', axis=1)

        # save results
        result_df.to_csv(output_file_name, index=False)
        print_log("Done and saved")


    except Exception as e:
        print_log(str(e))
        print_log(traceback.format_exc())


# we should check if the method is main to call it from other scripts and threds
if __name__ == '__main__':
    # freeze support allows to use multiprocessing on Windows
    multiprocessing.freeze_support()
    main()
