# [🇫🇷] Brouillon pour l'organisation de la doc de RTMet
*[🇬🇧] Draft (in french) for documentation.*

La documentation suit les principes décrits par [Diátaxis](https://diataxis.fr/).

<img src="https://diataxis.fr/_images/diataxis.png" alt="Diátaxis Quadrant" width="300" />

## À quoi sert RTMet? *( Is RTMet for me ?)*
Présuposé sur les données (off-line ou realtime):
- HRMS (High Resolution Mass Spectrometry)
- FIA (Injection Directe, l'axe temporel n'est pas un chromatogramme)
- Acquisitions ordonnées dans le temps

Présupposé pour le real-time: vous avez déjà automatisé le couplage prélèvement d'échantillons fermenteur + acquisition par un spectromètre de masse



## Liste de choses à aborder
***[!] = pas encore implémenté, donc pas à documenter***

- Installation:
    - Workflow et dépendances obligatoires
    - [!] Relier le workflow à un spectromètre de masse
    - (optionnel) Connecter le workflow à InfluxDB

- Tuto: prise en main: 
    - Installer le projet *(redirige vers)*
    - Créer une run (copie de travail) du workflow
    - Config utilisateur (mais ne pas laisser de choix dans un tuto!). On utilise un jeu de donnée de tuto.
    - Lancer la run (en spécifiant condition d'arrêt)
    - Observer l'exécution des tâches dans le TUI
    - Observer les résultats être créés au fur et à mesure dans share/
    - Décrire les données produites

- How-to (ou Tuto?): offline avec vos propres données:
    - modifier config utilisateur (source): 
        - vos métabolites d'intérêt
        - choix %TIC: décider en traitant manuellement un échantillon avec `binner-cli`
        - Tolérance (ppm) pour l'identification
    - créer la run
    - mettre vos `.raws` (bien nommés) dans raws/
    - puis comme le tuto précédent

- How-To: Comment monitorer et controler le workflow ?
    - TUI
    - Web GUI
    - Lancer, Arreter, Réinstaller, Logs, ...

- How-To: Comment visualiser ses résultats avec InfluxDB ?
    - Prérequis: InfluxDB *(redirige vers)*
    - Filtrer données
    - Choisir type de graphique
    - Créer un dashboard

- How-to: automatisation de l'échantillonnage et de l'acquisition. Rediriger vers [Cortada-Garcia et al.](https://doi.org/10.1002%2Fbit.28173) et autres publis

- [!] How-to: Analyser et visualiser en temps réel le métabolisme dans le fermenteur
    - Prérequis:
        - Prise d'échantillon et acquisition du spectro déjà automatisé *(redirige vers)*,
        - Workflow installé *(redirige vers)*,
        - connecté au pc d'acquisition du spectro *(redirige vers)*
        - connecté à une instance InfluxDB *(redirige vers)*,
    - Lancer une run du workflow
    - Lancer le spectro/fermenteur

- Référence:
    - Dépendances logicielles (notamment outils bioinfo)
    - Tâches du workflow Cylc
    - scripts dans lib/python
    - Outils CLI dans bin/

- Glossaire
    - FIA/HRMS/FIA-HRMS
    - workflow run

- Contribuer

- License