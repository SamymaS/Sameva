# 0006. Défi de capture : prouver qu'une photo vient d'être prise

- **Statut** : Proposé (implémenté, en attente de validation sur appareil)
- **Date** : 2026-10-21

---

## Contexte

L'Oracle juge le contenu d'une photo, pas sa date. Une ancienne photo de
chambre rangée serait acceptée pour la quête du jour. La v1.0.5 imposait la
caméra (`ImageSource.camera`), mais c'est une contrainte du client : une app
modifiée, un appel direct à l'API ou une application caméra tierce (l'intent
Android de capture peut être servi par n'importe quelle app) peut fournir
n'importe quel fichier. L'EXIF est falsifiable. Le serveur n'a aujourd'hui
aucun moyen de vérifier l'instant de prise de vue.

## Décision

Le serveur impose un défi imprévisible, que seule une photo prise après lui
peut contenir, et le vérifie sans le révéler au modèle.

1. À l'ouverture de l'écran de preuve, l'app appelle `oracle_challenge` : le
   serveur tire un geste parmi 7 et un nombre à 2 chiffres à écrire sur un
   papier (630 combinaisons), valables 3 minutes (+60 s pour l'envoi). En mode
   « sans les mains » (préférence stockée côté serveur), un nombre à 3 chiffres
   seul (900 possibilités).
2. Une seule relance par quête, quel que soit le mode ; plafonds de 10 défis
   par quête et 40 par joueur et par jour. Une photo de chaque geste préparée
   à l'avance ne sert donc à rien : le nombre change à chaque défi.
3. La photo est envoyée avec `challenge_id` ; `oracle_begin` refuse un défi
   absent, expiré, déjà utilisé, remplacé ou d'une autre quête.
4. Vérification à l'aveugle : MougiBot ne reçoit pas le défi attendu. Il
   décrit ce qu'il voit (`geste_observe` dans une liste fermée, `nombre_observe`
   manuscrit) et `oracle_resolve` compare. Ni la complaisance du modèle ni une
   injection dans le titre ne peuvent « valider le défi ».
5. L'image est décodée et réencodée côté serveur (JPEG 1280 px, sans EXIF) ;
   une image indécodable n'est pas analysée.
6. L'empreinte perceptuelle (dHash) n'est qu'un signal d'audit
   (`near_duplicate_of`), jamais bloquant : le défi garantit déjà la
   fraîcheur, et une même pièce photographiée chaque jour sous le même angle
   ne doit pas être refusée.
7. Panne de l'IA : énergie rendue et défi réutilisable dans son délai.
   Réponse inexploitable du modèle : rien n'est rendu (pas d'appels gratuits),
   et les analyses en erreur sont plafonnées à 10 par jour.

## Alternatives écartées

- **Se fier à la caméra in-app** : invérifiable côté serveur (voir Contexte).
- **Date EXIF** : modifiable avec n'importe quel outil, souvent supprimée.
- **Play Integrity / App Attest seuls** : prouvent que l'app est authentique,
  pas que la photo est récente ; prévus en complément au Sprint 8.
- **Geste seul** (première version) : 7 possibilités, contournable avec une
  photo préparée par geste et des relances (relevé par la revue de sécurité).
- **Objet du quotidien** : déjà présent sur beaucoup d'anciennes photos.
- **Communiquer le défi au modèle et lui demander « est-il visible ? »** :
  sensible à la complaisance et aux injections ; remplacé par la description
  à l'aveugle.

## Conséquences

- Positif : une ancienne photo, quel que soit le canal, ne valide plus rien.
- Négatif : une étape de plus pour le joueur (écrire deux chiffres) ; un
  faux négatif de l'IA (geste mal vu) coûte une énergie mais n'entre pas dans
  le score de crédibilité. Le refus est explicite et propose aussitôt un
  nouveau défi. À mesurer en bêta : si la friction pèse trop, le nombre peut
  être réservé aux quêtes de difficulté 3 et 4 via `game_config`.
- Risques résiduels :
  - un geste réel devant un écran affichant une ancienne photo : le prompt le
    traite comme une capture d'écran ;
  - un retouche express (outil d'IA générative qui ajoute une main faisant le
    geste sur une ancienne photo) dans la fenêtre de 4 minutes : possible mais
    coûteux et répétitif. Parades prévues au Sprint 8 : caméra intégrée à l'app
    (plus d'import de fichier possible sur un client authentique), Play
    Integrity / App Attest pour refuser les clients modifiés, et consigne
    MougiBot de détection des incrustations.
- À valider sur le S918B : lisibilité de la carte du défi, taux de faux
  négatifs de MougiBot sur les gestes, temps de bout en bout.
