#'Produire des graphiques avec les donnees obtenues grace a la fonction donnees_meteo_station
#'
#'La fonction utilise les fonctions des librairies ggplot et dplyr pour agreger les donnees par jour puis produire deux graphiques.
#'Lors de son initialisation elle verifie que les libraires necessaires sont bien installees, et que les donnees sont au bon format.
#' @param donnees : un data_frame contenant au moins les colonnes suivantes:
#'   - Date_Heure, POSIXct
#'   - Temp_C, numeric
#'   - Vit_du_vent_km_h, numeric
#' @param mois : l'utilisateur peut preciser un mois en particulier pour le graphique, par defaut 0 : affiche tous les mois de l’annee
#' @param graphiques : "t" pour juste le graphique des temperatures, "v" pour le graphique de la vitesse du vent et par defaut "tv" pour les deux graphiques.
#' @examples
#' dm <-donnees_meteo_station(114)
#' graphique_meteo(dm)
#' graphique_meteo(dm,mois=7,"t")
#' @import dplyr ggplot2 cowplot
#' @export
graphique_meteo <-
  function(donnees,mois=0,graphiques="tv"){
    #Verifie que les donnees sont au bon format
    if (!is.data.frame(donnees) | !inherits(donnees$Date_Heure, "POSIXct") | !is.numeric(donnees$Temp_C) | !is.numeric(donnees$Vit_du_vent_km_h)){
      stop("Erreur, la variable n'est pas de type data_frame ou ne contient pas les donnees necessaires a la realisation des graphiques
  Les colonnes suivantes doivent être presentes :
         Date_Heure, POSIXct
         Temp_C, numeric
         Vit_du_vent_km_h, numeric ")
    }
    #Verifie que dplyr, ggplot2 et cowplot sont installees
    for (package in c("dplyr", "ggplot2","cowplot")) {
      if (!require(package, character.only=T, quietly=F)) {
        warning("Certaines librairies ne sont pas chargees")
        requireNamespace(package)
        }
    }




    #Reduire le graphique a un mois en particulier
    mois_legende =""
    if (mois>=1 & mois<=12 ){
      donnees <- donnees[donnees$Mois == as.integer(mois),]
      mois_legende <- paste(" - Mois :",mois)
    }

    #Nous reprenons les mêmes instructions qui ont servi a construire le graphique au dernier chapitre
    Agrege_jour <- donnees %>%
      mutate(Jour_2 = as.character.Date(Date_Heure,"%m-%d"))%>% #Necessaire sinon va agreger par jour de la semaine
      group_by(Annee,Nom_de_la_Station,Jour_2)%>%
      summarise(meanTC=mean(Temp_C,na.rm=TRUE),maxTC=max(Temp_C,na.rm=TRUE),maxVIT=max(Vit_du_vent_km_h,na.rm=TRUE))
    #graphique temperatures
    temperatures <- Agrege_jour %>%
      ggplot(aes(x=Jour_2))+
      geom_line(aes(y=maxTC,color="Maximum Journalier C"),group=1)+
      geom_line(aes(y=meanTC,color="Moyenne Journalière C"),group=2)+
      labs(title=paste("Temperatures a la station \n",Agrege_jour$Nom_de_la_Station,"-",Agrege_jour$Annee,mois_legende), y="Temperature C", x="Jour", colour="Temperatures")+
      theme_classic()+
      theme(legend.position="bottom")
    #graphique vent
    vent <- Agrege_jour %>%
      ggplot(aes(x=Jour_2))+
      geom_col(aes(y=maxVIT,fill="vitesse maximale du vent"))+
      labs(title=paste("Vitesse maximale du vent a la station \n",Agrege_jour$Nom_de_la_Station,"-",Agrege_jour$Annee,mois_legende), y="Vitesse km/h", x="Jour",fill="")+
      scale_fill_manual(values = c("vitesse maximale du vent" = "steelblue"))+
      theme_classic()+
      theme(legend.position="bottom")
    #graphique final

    if (graphiques=="tv"){
      plot_grid(temperatures,vent, nrow=2,ncol=1)
    }else if (graphiques=="t") {
      temperatures
    }else if (graphiques=="v") {
      vent
    }

  }
