from bs4 import BeautifulSoup
import pandas as pd
import requests
import json
import csv
import re





def get_brands():

	
	
	headers = {
		'accept': 'application/json, text/plain, */*',
		'accept-language': 'en-US,en;q=0.9,ar-TN;q=0.8,ar;q=0.7',
		'cache-control': 'no-cache',
		'origin': 'https://www.evspecifications.com/',
		'pragma': 'no-cache',
		'referer': 'https://www.evspecifications.com/',
		'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36',
	}
	while True:
		try:
		
			response=requests.get("https://www.evspecifications.com/",headers=headers)
			if response.status_code==200:
				break
			
		except:
			pass



	brands=[]
	html=response.text
	soup=BeautifulSoup(html,"html.parser")
	
	for brand in soup.find("div",{"class":"brand-listing-container-frontpage"}).find_all("a"):
		
		brand_name=brand.text
		brand_url=brand["href"]
		print(" "+brand_name+" : "+brand_url)
		brands.append([brand_name,brand_url])
		
	return brands
	
	


def get_models(brand):

	headers = {
		'accept': 'application/json, text/plain, */*',
		'accept-language': 'en-US,en;q=0.9,ar-TN;q=0.8,ar;q=0.7',
		'cache-control': 'no-cache',
		'origin': 'https://www.evspecifications.com/',
		'pragma': 'no-cache',
		'referer': 'https://www.evspecifications.com/',
		'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36',
	}
	while True:
		try:
		
			response=requests.get(brand[1],headers=headers)
			if response.status_code==200:
				break
			
		except:
			pass

	
	html=response.text
	soup=BeautifulSoup(html,"html.parser")
	
	regex=re.compile("model_.*")
	
	models=[]
	for model in soup.find_all("div",{"id":regex}):
	
		model_url=model.find("a")["href"]
		models.append([brand[0],brand[1],model_url])
		
		
		
	return models



def fetch_model(model):

	headers = {
		'accept': 'application/json, text/plain, */*',
		'accept-language': 'en-US,en;q=0.9,ar-TN;q=0.8,ar;q=0.7',
		'cache-control': 'no-cache',
		'origin': 'https://www.evspecifications.com/',
		'pragma': 'no-cache',
		'referer': 'https://www.evspecifications.com/',
		'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36',
	}
	while True:
		try:
		
			response=requests.get(model[2],headers=headers)
			if response.status_code==200:
				break
			
		except:
			pass

	
	html=response.text
	soup=BeautifulSoup(html,"html.parser")
	
	
	model_name= soup.find("h1").text.split("- Specifications")[0].strip()
	car_image=soup.find("div",{"id":"model-image"})["style"].split("url(")[1].split(");")[0]
	
	car_details={
	
		"Brand Name":model[0],
		"Brand URL":model[1],
		"Model Name":model_name,
		"Model URL": model[2],
		"Car Image":car_image
		
	}
	brief_specifications=soup.find("div",{"id":"model-brief-specifications"}).find_all("b")
	
	
	for specification in brief_specifications:
		
		specification_key=specification.text.strip()
		specification_value=specification.next.next.strip().split(":")[1].strip()
		
		if specification_value[-1]==",":
			
			specification_value=specification_value[:-1]
			
		if specification_key in car_details:
			specification_key=specification_key+"_2"
		
		car_details[specification_key]=specification_value


	tables=soup.find_all("table",{"class":"model-information-table row-selection"})
	
	headers_list=[
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
		
		header=table.find_previous("header").find("h2").text.strip()
		if header in headers_list:
			for tr in table.find_all("tr"):
				
				specification_key=header+"_"+tr.find_all("td")[0].find("p").previous.strip()
				specification_value=tr.find_all("td")[1].text.strip()	
				car_details[specification_key]=specification_value

	
	return car_details
	
	
if __name__=='__main__':

	brands=get_brands()
		
	cars=[]
	
	for brand in brands:
	
		models=get_models(brand)
		for model in models:
			car_details=fetch_model(model)
			print(car_details)
			cars.append(car_details)
			
	
	keys = [i for s in [d.keys() for d in cars] for i in s]

	
	
	with open("cars.json", 'w', encoding='utf-8') as outfile:
		json.dump(cars, outfile, sort_keys=False, indent=4, ensure_ascii = False)
	
	df = pd.read_json ("cars.json")
	df.to_csv ("cars.csv", index = None)