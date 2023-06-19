import http.cookiejar as cookielib
from pathlib import Path
from io import BytesIO
import os
import sys
import time
import random
import zipfile
import requests
from git import Repo
from tqdm import tqdm

PROJECT_LINK = "https://www.overleaf.com/project/648c2bafed1243937ceb97d5"

path = Path(__file__).resolve().parent
os.chdir(path)

cj = cookielib.MozillaCookieJar('cookies.txt')
cj.load(ignore_expires=True)
for cookie in cj:
	cookie.expires = time.time() + 14 * 24 * 3600

USER_AGENTS = [ #List obtained from https://techblog.willshouse.com/2012/01/03/most-common-user-agents/
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36",
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:94.0) Gecko/20100101 Firefox/94.0",
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36",
	"Mozilla/5.0 (Windows NT 10.0; rv:91.0) Gecko/20100101 Firefox/91.0",
	"Mozilla/5.0 (X11; Linux x86_64; rv:94.0) Gecko/20100101 Firefox/94.0",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15",
	"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:94.0) Gecko/20100101 Firefox/94.0",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:94.0) Gecko/20100101 Firefox/94.0",
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Safari/537.36"
]

USER_AGENT = random.choice(USER_AGENTS)
	

def download(url):
	global cj
	headers = {
		"authority": "www.overleaf.com",
		"Referer": "https://www.overleaf.com/project",
		"Pragma": "no-cache",
		"User-Agent": USER_AGENT
	}
	response = requests.get(url, stream=True, headers=headers, cookies=cj)
	total_size_in_bytes= int(response.headers.get('content-length', 0))
	print(f"Zip size: {total_size_in_bytes} bytes")
	block_size = 1024 #1 Kibibyte
	progress_bar = tqdm(total=total_size_in_bytes, unit='iB', unit_scale=True, desc="Downloading project zip", ncols=16)
	with BytesIO() as file:
		for data in response.iter_content(block_size):
			progress_bar.update(len(data))
			file.write(data)
		progress_bar.close()
		if total_size_in_bytes != 0 and progress_bar.n != total_size_in_bytes:
			print("ERROR, something went wrong")

		print("Extracting zip file")
		file.seek(0)
		z = zipfile.ZipFile(file)
		z.extractall()
		z.close()

def gitPush(gitPath, commitMessage):
	print(f"Using '{gitPath}' as git path")
	try:
		repo = Repo(gitPath)
		repo.git.add(update=True)
		print(f"Committing with message '{commitMessage}'")
		repo.index.commit(commitMessage)
		origin = repo.remote(name='origin')
		origin.push()
	except:
		print('Some error occured while pushing the code')   


args = sys.argv.copy()
args = args[1:]
commitMessage = " ".join(args)

downloadLink = PROJECT_LINK + "/download/zip"
download(downloadLink)
gitPath = path / Path(".git/")
gitPush(gitPath, commitMessage)
