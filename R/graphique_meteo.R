#'Produire des graphiques avec les données obtenues grâce à la fonction donnees_meteo_station
#'
#'La fonction utilise les fonctions des librairies ggplot et dplyr pour agréger les données par jour puis produire deux graphiques.
#'Lors de son initialisation elle vérifie que les libraires nécessaires sont bien installées, et que les données sont au bon format.
#' @donnees : un data_frame contenant au moins les colonnes suivantes:
#' @Date_Heure, POSIXct
#' @Temp_C, numeric
#' @Vit_du_vent_km_h, numeric
#' @mois : l’utilisateur peut préciser un mois en particulier pour le graphique, par défaut 0 : affiche tous les mois de l’année
#' @graphiques : « t » pur juste le graphique des températures, « v »pour le graphique de la vitesse du vent et par défaut « tv » pour les deux graphiques.
#' @examples
#' graphique_meteo(meteo_station_30165_annee_2020)
#' graphique_meteo(meteo_station_30165_annee_2020,mois=7,"v")

#' @export
graphique_meteo <-
  function(donnees,mois=0,graphiques="tv"){
    #Vérifie que les données sont au bon format
    if (!is.data.frame(donnees) | !inherits(donnees$Date_Heure, "POSIXct") | !is.numeric(donnees$Temp_C) | !is.numeric(donnees$Vit_du_vent_km_h)){
      stop("Erreur, la variable n'est pas de type data_frame ou ne contient pas les données nécessaires à la réalisation des graphiques
  Les colonnes suivantes doivent être présentes :
         Date_Heure, POSIXct
         Temp_C, numeric
         Vit_du_vent_km_h, numeric ")
    }
    #Vérifie que dplyr, ggplot2 et cowplot sont installées
    for (package in c("dplyr", "ggplot2","cowplot")) {
      if (!require(package, character.only=T, quietly=F)) {
        warning("Certaines librairies ne sont pas chargées")
        install.packages(package)
        library(package, character.only=T)
      }
    }




    #Réduire le graphique à un mois en particulier
    if (mois>=1 & mois<=12 ){
      donnees <- donnees[donnees$Mois == as.integer(mois),]

    }

    #Nous reprenons les mêmes instructions qui ont servi à construire le graphique au dernier chapitre
    Agrege_jour <- donnees %>%
      mutate(Jour_2 = as.character.Date(Date_Heure,"%m-%d"))%>% #Nécessaire sinon va agréger par jour de la semaine
      group_by(Annee,Nom_de_la_Station,Jour_2)%>%
      summarise(meanTC=mean(Temp_C,na.rm=TRUE),maxTC=max(Temp_C,na.rm=TRUE),maxVIT=max(Vit_du_vent_km_h,na.rm=TRUE))
    #graphique temperatures
    temperatures <- Agrege_jour %>%
      ggplot(aes(x=Jour_2))+
      geom_line(aes(y=maxTC,color="Maximum Journalier C"),group=1)+
      geom_line(aes(y=meanTC,color="Moyenne Journalière C"),group=2)+
      labs(title=paste("Temperatures à la station \n",Agrege_jour$Nom_de_la_Station,"-",Agrege_jour$Annee), y="Température C", x="Jour", colour="Températures")+
      theme_classic()+
      theme(legend.position="bottom")
    #graphique vent
    vent <- Agrege_jour %>%
      ggplot(aes(x=Jour_2))+
      geom_col(aes(y=maxVIT,fill="vitesse maximale du vent"))+
      labs(title=paste("Vitesse maximale du vent à la station \n",Agrege_jour$Nom_de_la_Station,"-",Agrege_jour$Annee), y="Vitesse km/h", x="Jour",fill="")+
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
