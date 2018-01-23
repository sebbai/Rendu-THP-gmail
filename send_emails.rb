require 'rubygems' 
require 'nokogiri'
require 'open-uri'
require "google_drive"
require 'json'
require 'csv'
require 'dotenv'
require 'gmail'			# <= Gems nécessaire au bon fonctionnement du programme.
Dotenv.load

#Récupère les adresses mails de l'url envoyé en paramètre
def get_the_email_of_a_townhal_from_its_webpage(url)
	page = Nokogiri::HTML(open(url))

	page.css("tr > td > p > font").each do |email|
		if email.text.include?"@"
			return email.text[1...email.text.length]  # <= Pour retourné à partir de deuxieme caractère le 1er étant un espace.
		end
	end

end

# Récupère la liste des mairies de Seine-Saint-Denis(93) et les mails respectifs avec la méthode "get_the_email_of_a_townhal_from_its_webpage".
def get_all_the_urls_of_93_townhalls
	
	page = Nokogiri::HTML(open("http://annuaire-des-mairies.com/seine-saint-denis.html"))
	list_url = page.css("a.lientxt")
	list_url.each do |url|
		good_link = "http://annuaire-des-mairies.com" + url['href'][1..url['href'].length]
		$hash_town[url.text] = get_the_email_of_a_townhal_from_its_webpage(good_link)
	end 
	
	return $hash_town
end

# Envoi les mails en se connectant à un compte donné au adresse récupérer par la méthode get_all_the_urls_of_93_townhalls.
def send_email_to_line(ws)

	gmail = Gmail.connect(ENV['IDENTIFIANT'], ENV['MDP'])	# <= connection via un fichier .env contenenant les info de login.
	
	(1..ws.num_rows).each do |row|
		email = gmail.compose do
			to ws[row, 2]
			subject "Présentation"
			body "Bonjour,
Je m'appelle Sébastien, je suis élève à une formation de code gratuite, ouverte à tous, sans restriction géographique, ni restriction de niveau. La formation s'appelle The Hacking Project (http://thehackingproject.org/). Nous apprenons l'informatique via la méthode du peer-learning : nous faisons des projets concrets qui nous sont assignés tous les jours, sur lesquel nous planchons en petites équipes autonomes. Le projet du jour est d'envoyer des emails à nos élus locaux pour qu'ils nous aident à faire de The Hacking Project un nouveau format d'éducation gratuite.

Nous vous contactons pour vous parler du projet, et vous dire que vous pouvez ouvrir une cellule à #{ws[row, 2]}, où vous pouvez former gratuitement 6 personnes (ou plus), qu'elles soient débutantes, ou confirmées. Le modèle d'éducation de The Hacking Project n'a pas de limite en terme de nombre de moussaillons (c'est comme cela que l'on appelle les élèves), donc nous serions ravis de travailler avec #{ws[row, 2]} !

Charles, co-fondateur de The Hacking Project pourra répondre à toutes vos questions : 06.95.46.60.80"	
		end
		gmail.deliver(email) # <= Envoi le mail en fin de boucle
	end
end

#Pour se connecter à Google Drive et récupérer un fichier spreadsheet.
session = GoogleDrive::Session.from_config("config.json")
ws = session.spreadsheet_by_key("1WXjQ09qSdy_vQyvMMqt7UFewDTxBWatb57F8UyKch_I").worksheets[0]

$hash_town = Hash.new

get_all_the_urls_of_93_townhalls  #Appel de la méthode après avoir récupérer le fichier spreadsheet.

i = 1 	# <= i pour servir d'index  et se déplacer de 1 ligne en 1 ligne honrizontalement,
	  	# à chaque tour de la boucle qui suit le 2eme paramètre étant les lignes verticales,	  
	  	# qui ne changeront vu qu'elles désignent respectivement la 1er et 2eme colonnes.
$hash_town.each do |city, email|
	ws[i, 1] = city
	ws[i, 2] = email
	i += 1
	
end

ws.save  # <= Pour sauvegarder dans le drive les changements apportés au fichier spreadsheet.

send_email_to_line(ws)	# <= Appel de la méthode pour envoyé les mails à partir du fichier spreadsheet passer en paramètre(ws). 
 

 # Conversions
File.open("temp.json","w") do |f|		#<= w pour donné le droit d'écriture}	<= pour convertir en json
	f.write($hash_town.to_json)
end


CSV.open("file.csv","wb") do |csv|		#<= pour convertir en CSV
	$hash_town.each do |key, value|
		csv << [key,value]
	end
end