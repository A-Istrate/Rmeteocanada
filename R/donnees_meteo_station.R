#' Récupérer et formater les données d'une station météo d’Environnement Canada
#'
#' La fonction va aller chercher les données sur le serveur d’Environnement Canada, concaténer les 12 fichiers mensuels,
#' formater et nettoyer les données. Puis finalement soit enregistrer directement un data frame dans l’environnement
#' global soit retourner un data frame pour être travaillé par l’utilisateur en aval.
#' @stationid : permet à l’utilisateur de préciser quelle station météo il souhaite consulter. Liste complète (fichier csv officiel d’Environnement et Changement climatique Canada ) : https://drive.google.com/file/d/1MnCvrLiCz_V8y8gCYMX_Mucerupp5UsF/view?usp=sharing
#' Par défaut va chercher les données liées à la station de l’aéroport de Montréal (30165).
#'	@year : permet de choisir l’année de téléchargement, 2020 par défaut
#' @returndf : précise si la fonction enregistre le data frame contenant les données dans l’environnement global (par défaut) ou s’il retourne un data frame avec retrun().
#'	@savecsv : permet d’enregistrer les données récupérés, nettoyées et compilées dans un csv en local.  False par défaut.
#'	@force_download : pour éviter de surcharger les serveurs d’Environnement Canada, la fonction ne télécharge les données que si elles n’existent pas déjà dans le répertoire local, possibilité de forcer le téléchargement, pour mettre à jour par exemple.
#'	@examples
#'	donnees_meteo_station()
#'	donnees_meteo_station(stationid=27226,year=2019,savecsv=TRUE)

donnees_meteo_station = function(stationid=30165,year=2020, returndf=FALSE, savecsv=FALSE, force_download=FALSE){

  #on créé le dossier pour les téléchargements si celui-ci n'existe pas
  dir_sa <-paste0("meteo_station_",stationid,"_annee_",year)
  if (!dir.exists(dir_sa) ){
    dir.create(dir_sa)
  }

  #on télécharge les 12 fichiers correspondant aux mois de l'année pour une station donnée

  for (i in 1:12){
    urlcsv <- paste0("https://climat.meteo.gc.ca/climate_data/bulk_data_f.html?format=csv&stationID=",stationid,"&Year=",year,"&Month=",i,"&Day=14&timeframe=1&submit=++T%C3%A9l%C3%A9charger+%0D%0Ades+donn%C3%A9es")
    localfile <- paste0("./",dir_sa,"/meteo",i,".csv")

    #vérifie si le fichier existe déjà ou si l'utilisateur a indiqué qu'il souhaite télécharger à nouveau avant de télécharger les données
    if(force_download | !file.exists(localfile)){
      download.file(url=urlcsv,destfile=localfile, method='curl')
    }
    #lecture du fichier mensuel et ajout à un data frame pour l'annee voulue
    donnees_meteo_temp <-read.csv(localfile, encoding = "UTF-8" )
    if (i==1) {
      donnees_meteo <- donnees_meteo_temp;

    }else {
      donnees_meteo <- rbind(donnees_meteo,donnees_meteo_temp)
    }
  }

  #On nettoie le nom de colonnes
  donnees_meteo <- donnees_meteo[-c(11,13,15,17,19:21,23,25,27,28)]
  names(donnees_meteo)[1]<-"Longitude"
  names(donnees_meteo)[2]<-"Latitude"
  names(donnees_meteo) <- gsub(x = names(donnees_meteo), pattern = "\\.+", replacement = "_")
  names(donnees_meteo) <- gsub(x = names(donnees_meteo), pattern = "é", replacement = "e")
  names(donnees_meteo) <- gsub(x = names(donnees_meteo), pattern = "à", replacement = "a")
  names(donnees_meteo) <- gsub(x = names(donnees_meteo), pattern = "_$", replacement = "")

  #Afin de pouvoir utiliser les donnée on transformes certaines colonnes en numérique
  #besoin de transformer les virgules en points pour la conversion
  conversion_en_numerique =function(x){
    as.numeric(gsub(",", ".",x))
  }

  #sapply sur les colonnes nécessitant une conversion
  donnees_meteo[,c(10,11,15)] <- sapply(donnees_meteo[,c(10,11,15)], conversion_en_numerique  )

  #On transforme la date_heure en POSIXct
  donnees_meteo$Date_Heure <- as.POSIXct(donnees_meteo$Date_Heure,tz = "" )

  #Si indiqué on sauvegarde une copie du data frame nettoyé en fichier csv
  if(savecsv){
    write.csv(donnees_meteo,paste0("./",dir_sa,"/",dir_sa,".csv"))
  }

  #on retourne le data frame selon l'option choisie
  if (returndf == FALSE) {

    assign(dir_sa,donnees_meteo,envir = .GlobalEnv)

  } else {

    return(donnees_meteo)

  }
}