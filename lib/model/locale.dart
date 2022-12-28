import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:social_news_app/model/helpers.dart';

abstract class TRGeneral {
  TRGeneral._();

  static String get forYou {
    switch (locale) {
      case LC.en:
        return "For You";
      case LC.es:
        return "Para Ti";
    }
  }

  static String get search {
    switch (locale) {
      case LC.en:
        return "Search";
      case LC.es:
        return "Buscar";
    }
  }

  static String get trending {
    switch (locale) {
      case LC.en:
        return "Trending";
      case LC.es:
        return "Tendencias";
    }
  }

  static String get settings {
    switch (locale) {
      case LC.en:
        return "Settings";
      case LC.es:
        return "Ajustes";
    }
  }

  static String get newSource {
    return "New Source";
  }

  static String get gotIt {
    switch (locale) {
      case LC.en:
        return "Got It";
      case LC.es:
        return "Entiendo";
    }
  }

  static String get gettingStarted {
    switch (locale) {
      case LC.en:
        return "Getting Started";
      case LC.es:
        return "Empezando";
    }
  }

  static String get displayName {
    switch (locale) {
      case LC.en:
        return "Display Name";
      case LC.es:
        return "Nombre Para Mostrar";
    }
  }

  static String get password {
    switch (locale) {
      case LC.en:
        return "Password";
      case LC.es:
        return "Contraseña";
    }
  }

  static String get email {
    switch (locale) {
      case LC.en:
        return "Email";
      case LC.es:
        return "Email";
    }
  }

  static String get renterPassword {
    switch (locale) {
      case LC.en:
        return "Re-enter password";
      case LC.es:
        return "Escriba la contraseña otra vez";
    }
  }

  static String get system {
    switch (locale) {
      case LC.en:
        return "System";
      case LC.es:
        return "Sistema";
    }
  }

  static String get dark {
    switch (locale) {
      case LC.en:
        return "Dark";
      case LC.es:
        return "Oscura";
    }
  }

  static String get light {
    switch (locale) {
      case LC.en:
        return "Light";
      case LC.es:
        return "Claro";
    }
  }

  static String get cancel {
    switch (locale) {
      case LC.en:
        return "Cancel";
      case LC.es:
        return "Cancelar";
    }
  }

  static String get close {
    switch (locale) {
      case LC.en:
        return "Close";
      case LC.es:
        return "Cerca";
    }
  }

  static String get done {
    switch (locale) {
      case LC.en:
        return "Done";
      case LC.es:
        return "Hecho";
    }
  }

  static String get confirm {
    switch (locale) {
      case LC.en:
        return "Confirm";
      case LC.es:
        return "Confirmar";
    }
  }

  static String get okay {
    switch (locale) {
      case LC.en:
        return "Okay";
      case LC.es:
        return "De Acuerdo";
    }
  }

  static String get delete {
    switch (locale) {
      case LC.en:
        return "Delete";
      case LC.es:
        return "Eliminar";
    }
  }

  static String get remove {
    switch (locale) {
      case LC.en:
        return "Remove";
      case LC.es:
        return "Remover";
    }
  }

  static String get removed {
    switch (locale) {
      case LC.en:
        return "Removed";
      case LC.es:
        return "Remota";
    }
  }

  static String get postVerb {
    switch (locale) {
      case LC.en:
        return "Post";
      case LC.es:
        return "Enviar";
    }
  }

  static String get postNoun {
    switch (locale) {
      case LC.en:
        return "Post";
      case LC.es:
        return "Correo";
    }
  }

  static String get commentNoun {
    switch (locale) {
      case LC.en:
        return "Comment";
      case LC.es:
        return "Comentario";
    }
  }

  static String get commentVerb {
    switch (locale) {
      case LC.en:
        return "Comment";
      case LC.es:
        return "Comentar";
    }
  }

  static String get discussion {
    switch (locale) {
      case LC.en:
        return "Discussion";
      case LC.es:
        return "Discusión";
    }
  }

  static String get critique {
    switch (locale) {
      case LC.en:
        return "Critique";
      case LC.es:
        return "Crítica";
    }
  }

  static String get reply {
    switch (locale) {
      case LC.en:
        return "Reply";
      case LC.es:
        return "Respuesta";
    }
  }

  static String get replies {
    switch (locale) {
      case LC.en:
        return "Replies";
      case LC.es:
        return "Respuestas";
    }
  }

  static String get preview {
    switch (locale) {
      case LC.en:
        return "Preview";
      case LC.es:
        return "Avance";
    }
  }

  static String get similar {
    switch (locale) {
      case LC.en:
        return "Similar";
      case LC.es:
        return "Similar";
    }
  }

  static String get edit {
    switch (locale) {
      case LC.en:
        return "Edit";
      case LC.es:
        return "Editar";
    }
  }

  static String get votedBy {
    switch (locale) {
      case LC.en:
        return "Voted By";
      case LC.es:
        return "Votado Por";
    }
  }

  static String get votesFromUser {
    switch (locale) {
      case LC.en:
        return "Votes From User";
      case LC.es:
        return "Votos De La Usuaria";
    }
  }

  static String get viewedBy {
    switch (locale) {
      case LC.en:
        return "Viewed By";
      case LC.es:
        return "Visto Por";
    }
  }

  static String get readLaterBy {
    switch (locale) {
      case LC.en:
        return "To Read Later By";
      case LC.es:
        return "Para Leer Más Tarde Por";
    }
  }

  static String get edited {
    switch (locale) {
      case LC.en:
        return "Edited";
      case LC.es:
        return "Editada";
    }
  }

  static String get errorOccurred {
    switch (locale) {
      case LC.en:
        return "An Error Occurred";
      case LC.es:
        return "Ocurrió Un Error";
    }
  }

  static String get follow {
    switch (locale) {
      case LC.en:
        return "Follow";
      case LC.es:
        return "Seguir";
    }
  }

  static String get unfollow {
    switch (locale) {
      case LC.en:
        return "Unfollow";
      case LC.es:
        return "Dejar De Seguir";
    }
  }

  static String get critiques {
    switch (locale) {
      case LC.en:
        return "Critiques";
      case LC.es:
        return "Críticas";
    }
  }

  static String get account {
    switch (locale) {
      case LC.en:
        return "Account";
      case LC.es:
        return "Cuenta";
    }
  }

  static String get credits {
    switch (locale) {
      case LC.en:
        return "Credits";
      case LC.es:
        return "Créditos";
    }
  }

  static String get reputation {
    switch (locale) {
      case LC.en:
        return "Reputation";
      case LC.es:
        return "Reputación";
    }
  }

  static String get credibility {
    switch (locale) {
      case LC.en:
        return "Credibility";
      case LC.es:
        return "Credibilidad";
    }
  }

  static String get anonymous {
    switch (locale) {
      case LC.en:
        return "Anonymous";
      case LC.es:
        return "Anónima";
    }
  }

  static String get posts {
    switch (locale) {
      case LC.en:
        return "Posts";
      case LC.es:
        return "Publicaciones";
    }
  }

  static String get comments {
    switch (locale) {
      case LC.en:
        return "Comments";
      case LC.es:
        return "Comentarios";
    }
  }

  static String get users {
    switch (locale) {
      case LC.en:
        return "Users";
      case LC.es:
        return "Usuarias";
    }
  }

  static String get tags {
    switch (locale) {
      case LC.en:
        return "Tags";
      case LC.es:
        return "Etiquetas";
    }
  }

  static String get tagsViewed {
    switch (locale) {
      case LC.en:
        return "Tags Viewed";
      case LC.es:
        return "Etiquetas Vistas";
    }
  }

  static String get preferences {
    switch (locale) {
      case LC.en:
        return "Preferences";
      case LC.es:
        return "Preferencias";
    }
  }

  static String get signIn {
    switch (locale) {
      case LC.en:
        return "Sign In";
      case LC.es:
        return "Registrarse";
    }
  }

  static String signInWith(String p) {
    switch (locale) {
      case LC.en:
        return "Sign in with $p";
      case LC.es:
        return "Iniciar Sesión Con $p";
    }
  }

  static double get signInButtonWidth {
    switch (locale) {
      case LC.en:
        return 200; // "Sign in with"
      case LC.es:
        return 250; // "Iniciar Sesión Con"
    }
  }

  static String get signOut {
    switch (locale) {
      case LC.en:
        return "Logout";
      case LC.es:
        return "Cerrar Sesión";
    }
  }

  static String get signInRequired {
    switch (locale) {
      case LC.en:
        return "Sign In Required";
      case LC.es:
        return "Inicio De Sesión Requerido";
    }
  }

  static String get doNotIgnore {
    switch (locale) {
      case LC.en:
        return "Don't Ignore";
      case LC.es:
        return "No Ignores";
    }
  }

  static String get report {
    switch (locale) {
      case LC.en:
        return "Report";
      case LC.es:
        return "Informar";
    }
  }

  static String get select {
    switch (locale) {
      case LC.en:
        return "Select";
      case LC.es:
        return "Seleccione";
    }
  }

  static String get unselect {
    switch (locale) {
      case LC.en:
        return "Unselect";
      case LC.es:
        return "Deseleccionar";
    }
  }

  static String get everywhere {
    switch (locale) {
      case LC.en:
        return "Everywhere";
      case LC.es:
        return "En Todas Partes";
    }
  }
}

class TRSorting {
  TRSorting._();

  static String get score {
    switch (locale) {
      case LC.en:
        return "Score";
      case LC.es:
        return "Puntaje";
    }
  }

  static String get credibility {
    switch (locale) {
      case LC.en:
        return "Credibility";
      case LC.es:
        return "Credibilidad";
    }
  }

  static String get upvotes {
    switch (locale) {
      case LC.en:
        return "Upvotes";
      case LC.es:
        return "Votos a Favor";
    }
  }

  static String get downvotes {
    switch (locale) {
      case LC.en:
        return "Downvotes";
      case LC.es:
        return "Votos Negativos";
    }
  }

  static String get controversial {
    switch (locale) {
      case LC.en:
        return "Controversial";
      case LC.es:
        return "Controlar";
    }
  }

  static String get newlyCreated {
    switch (locale) {
      case LC.en:
        return "Recently Created";
      case LC.es:
        return "Creado Recientemente";
    }
  }

  static String get recentlyUpdated {
    switch (locale) {
      case LC.en:
        return "Recently Updated";
      case LC.es:
        return "Recientemente actualizado";
    }
  }

  static String get recentlyAdded {
    switch (locale) {
      case LC.en:
        return "Recently Added";
      case LC.es:
        return "Recientemente Añadido";
    }
  }

  static String get relevance {
    switch (locale) {
      case LC.en:
        return "Relevance";
      case LC.es:
        return "Relevancia";
    }
  }
}

abstract class TRHome {
  TRHome._();

  static String addCreditsTitle(int amount) {
    switch (locale) {
      case LC.en:
        return "Added $amount Credit";
      case LC.es:
        return "Añadido $amount Créditos";
    }
  }

  static String addCreditsBody(int amount, int nextAmount) {
    switch (locale) {
      case LC.en:
        return "Added $amount Credit for daily login. Login again within 24 hours after ${utcMidnight()} for an additional ${nextAmount} credits";
      case LC.es:
        return "Se agregó $amount crédito por inicio de sesión diario. Inicie sesión nuevamente dentro de las 24 horas posteriores a las ${utcMidnight()} para obtener ${nextAmount} créditos adicionales";
    }
  }
}

abstract class TRSignUp {
  TRSignUp._();

  static String tooLong(String name, int max) {
    switch (locale) {
      case LC.en:
        return "$name must be at most $max characters long";
      default:
        return "";
    }
  }

  static String tooShort(String name, int min) {
    switch (locale) {
      case LC.en:
        return "$name must be at least $min characters long";
      default:
        return "";
    }
  }

  static String get passwordMismatch {
    switch (locale) {
      case LC.en:
        return "Passwords do not match";
      default:
        return "Las contraseñas no coinciden";
    }
  }

  static String get emailInvalid {
    switch (locale) {
      case LC.en:
        return "email address appears to be invalid";
      case LC.es:
        return "la dirección de correo electrónico parece no ser válida";
    }
  }
}

abstract class TRSignIn {
  static String get incorrectPasswordOrEmail {
    switch (locale) {
      case LC.en:
        return "Incorrect password or email address";
      case LC.es:
        return "Contraseña o dirección de correo electrónico incorrecta";
    }
  }

  static String get createAccount {
    switch (locale) {
      case LC.en:
        return "Create Account";
      case LC.es:
        return "Crear Una Cuenta";
    }
  }

  static String get forgotPassword {
    switch (locale) {
      case LC.en:
        return "Forgot Password";
      case LC.es:
        return "Has Olvidado Tu Contraseña";
    }
  }

  static String get justBrowse {
    switch (locale) {
      case LC.en:
        return "Just Browse";
      case LC.es:
        return "Solo Navega";
    }
  }

  static String get provideEmail {
    switch (locale) {
      case LC.en:
        return "Please provide an email address in the above field";
      case LC.es:
        return "Proporcione una dirección de correo electrónico en el campo de arriba";
    }
  }

  static String get sentPasswordReset {
    switch (locale) {
      case LC.en:
        return "Password reset link sent";
      case LC.es:
        return "Enlace de restablecimiento de contraseña enviado";
    }
  }
}

abstract class TRSettings {
  TRSettings._();

  static String get safeImage {
    switch (locale) {
      case LC.en:
        return "Preview image from only 'safe' sources";
      case LC.es:
        return "Vista previa de la imagen solo de fuentes 'seguras'";
    }
  }

  static String get areYouSureDelete {
    switch (locale) {
      case LC.en:
        return "Are you sure you want to permanently delete your account? All your data will be permanently deleted and cannot be recovered.";
      case LC.es:
        return "¿Está seguro de que desea eliminar su cuenta de forma permanente? Todos sus datos se eliminarán de forma permanente y no se podrán recuperar.";
    }
  }

  static String get deleteAccount {
    switch (locale) {
      case LC.en:
        return "Delete Account";
      case LC.es:
        return "Borrar Cuenta";
    }
  }

  static String get accountDetails {
    switch (locale) {
      case LC.en:
        return "Account Details";
      case LC.es:
        return "Detalles de la Cuenta";
    }
  }

  static String get theme {
    switch (locale) {
      case LC.en:
        return "Theme";
      case LC.es:
        return "Tema";
    }
  }

  static String get safeMode {
    switch (locale) {
      case LC.en:
        return "Safe Mode";
      case LC.es:
        return "Modo Seguro";
    }
  }

  static String get permission {
    switch (locale) {
      case LC.en:
        return "Permission";
      case LC.es:
        return "Permiso";
    }
  }

  static String get actions {
    switch (locale) {
      case LC.en:
        return "Actions";
      case LC.es:
        return "Comportamiento";
    }
  }

  static String get publicReadLater {
    switch (locale) {
      case LC.en:
        return "Public Read Later";
      case LC.es:
        return "Pública Leer Más Tarde";
    }
  }

  static String get publicViewedPosts {
    switch (locale) {
      case LC.en:
        return "Public Viewed Posts";
      case LC.es:
        return "Publicaciones Vistas Por El Público";
    }
  }

  static String get publicFollowedUsers {
    switch (locale) {
      case LC.en:
        return "Public Followed Users";
      case LC.es:
        return "Usuarios Públicos Seguidos";
    }
  }

  static String get publicIgnoredUsers {
    switch (locale) {
      case LC.en:
        return "Public Ignored Users";
      case LC.es:
        return "Usuarios Públicos Ignorados";
    }
  }

  static String get publicFollowedTags {
    switch (locale) {
      case LC.en:
        return "Public Followed Tags";
      case LC.es:
        return "Etiquetas Públicas Seguidas";
    }
  }

  static String get publicVotedPosts {
    switch (locale) {
      case LC.en:
        return "Public Voted Posts";
      case LC.es:
        return "Publicaciones Votadas Públicamente";
    }
  }

  static String get publicVotedComments {
    switch (locale) {
      case LC.en:
        return "Public Voted Comments";
      case LC.es:
        return "Comentarios Públicos Votados";
    }
  }

  static String get publicVotedUsers {
    switch (locale) {
      case LC.en:
        return "Public Voted Users";
      case LC.es:
        return "Usuarios Votados Públicos";
    }
  }

  static String get publicVotedTags {
    switch (locale) {
      case LC.en:
        return "Public Voted Tags";
      case LC.es:
        return "Etiquetas Votadas Por El Público";
    }
  }
}

abstract class TROnboard {
  TROnboard._();

  static String get followTags {
    switch (locale) {
      case LC.en:
        return "Follow Tags";
      case LC.es:
        return "Seguir Etiquetas";
    }
  }

  static String get followSources {
    switch (locale) {
      case LC.en:
        return "Follow Sources";
      case LC.es:
        return "Seguir Fuentes";
    }
  }
}

abstract class TREmailVerify {
  TREmailVerify._();

  static String get resend {
    switch (locale) {
      case LC.en:
        return "Resend Verification Link";
      case LC.es:
        return "Reenviar Enlace De Verificación";
    }
  }

  static String get verifyEmail {
    switch (locale) {
      case LC.en:
        return "Email Verification";
      case LC.es:
        return "Verificacion De Email";
    }
  }

  static String message(String email) {
    switch (locale) {
      case LC.en:
        return "Please click the verification link in the email sent to you "
            "(**$email**). If you did not receive "
            "an email you can resend the link by pressing the "
            "**Resend Verification Link** button below. Ensure that the email is "
            "not in the Junk folder.\n\n"
            "Without having a verified account you will not have functionality "
            "which allows you to participate in the New Source community.";
      case LC.es:
        return "Haga clic en el enlace de verificación en el correo electrónico "
            "que se le envió (**$email**). Si no recibió un correo electrónico, puede "
            "reenviar el enlace presionando el botón **Reenviar enlace de verificación** "
            "a continuación. Asegúrese de que el correo electrónico no esté en la carpeta "
            "de correo no deseado.\n\n"
            "Sin tener una cuenta verificada, no tendrá la "
            "funcionalidad que le permita participar en la comunidad New Source.";
    }
  }
}

abstract class TRCommentsPage {
  static String get threadWasDeleted {
    switch (locale) {
      case LC.en:
        return "Comment thread was deleted";
      case LC.es:
        return "El hilo de comentarios fue eliminado";
    }
  }

  static String get noCritiques {
    switch (locale) {
      case LC.en:
        return "No Critiques. Be the First to Evaluate the Post.";
      case LC.es:
        return "Sin críticas. Sea el primero en evaluar la publicación.";
    }
  }

  static String get noDiscussion {
    switch (locale) {
      case LC.en:
        return "No Comments. Be the First to Start the Discussion.";
      case LC.es:
        return "Sin comentarios. Se el primero en empezar la discusión.";
    }
  }

  static String get enterReply {
    switch (locale) {
      case LC.en:
        return "Enter a Reply";
      case LC.es:
        return "Introduce una respuesta";
    }
  }

  static String get createPost {
    switch (locale) {
      case LC.en:
        return "Create Post";
      case LC.es:
        return "Crear Publicación";
    }
  }

  static String get critiquePost {
    switch (locale) {
      case LC.en:
        return "Critique Post";
      case LC.es:
        return "Publicación De Crítica";
    }
  }

  static String get editPost {
    switch (locale) {
      case LC.en:
        return "Edit Post";
      case LC.es:
        return "Editar Post";
    }
  }

  static String get editComment {
    switch (locale) {
      case LC.en:
        return "Edit Comment";
      case LC.es:
        return "Editar Comentario";
    }
  }

  static String get mustSignIn {
    switch (locale) {
      case LC.en:
        return "You must sign in to make a post";
      case LC.es:
        return "Debes iniciar sesión para hacer una publicación";
    }
  }
}

abstract class TRAccountPage {
  TRAccountPage._();

  static String get viewed {
    switch (locale) {
      case LC.en:
        return "Viewed";
      case LC.es:
        return "Visto";
    }
  }

  static String get readLater {
    switch (locale) {
      case LC.en:
        return "Read Later";
      case LC.es:
        return "Leer Más Tarde";
    }
  }

  static String get usersFollowing {
    switch (locale) {
      case LC.en:
        return "Users Following";
      case LC.es:
        return "Usuarios Siguiendo";
    }
  }

  static String get usersIgnored {
    switch (locale) {
      case LC.en:
        return "Users Ignored";
      case LC.es:
        return "Usuarios Ignoradas";
    }
  }

  static String get followedBy {
    switch (locale) {
      case LC.en:
        return "Followed By";
      case LC.es:
        return "Seguido por";
    }
  }

  static String get ignoredBy {
    switch (locale) {
      case LC.en:
        return "Ignored By";
      case LC.es:
        return "Ignorado por";
    }
  }

  static String get tagsFollowing {
    switch (locale) {
      case LC.en:
        return "Tags Following";
      case LC.es:
        return "Etiquetas Siguientes";
    }
  }

  static String get createdContent {
    switch (locale) {
      case LC.en:
        return "Created Content";
      case LC.es:
        return "Contenido Creado";
    }
  }

  static String get collections {
    switch (locale) {
      case LC.en:
        return "Collections";
      case LC.es:
        return "Colecciones";
    }
  }

  static String get votedFor {
    switch (locale) {
      case LC.en:
        return "Voted For";
      case LC.es:
        return "Votado Por";
    }
  }
}

abstract class TRPosts {
  TRPosts._();

  static String get postMarkedRead {
    switch (locale) {
      case LC.en:
        return "Post Marked As Read";
      case LC.es:
        return "Post Marcada Como Leída";
    }
  }

  static String get addedToReadLater {
    switch (locale) {
      case LC.en:
        return "Added To Read Later";
      case LC.es:
        return "Agregado Para Leer Más Tarde";
    }
  }

  static String get ignoreUser {
    switch (locale) {
      case LC.en:
        return "Ignore User";
      case LC.es:
        return "Ignorar Usuaria";
    }
  }

  static String get confirmIgnoreUser {
    switch (locale) {
      case LC.en:
        return "Posts From This User Will Be Ignored";
      case LC.es:
        return "Las Publicaciones De Este Usuario Serán Ignoradas";
    }
  }
}

abstract class TRHelper {
  TRHelper._();

  static String get launchWebFailed {
    switch (locale) {
      case LC.en:
        return "Could Not Launch Website";
      case LC.es:
        return "No Se Pudo Iniciar El Sitio Web";
    }
  }

  static String get noResults {
    switch (locale) {
      case LC.en:
        return "No Items";
      case LC.es:
        return "No Hay Artículos";
    }
  }

  static String numberOfItems(int count) {
    switch (locale) {
      case LC.en:
        return "$count Items";
      case LC.es:
        return "$count Artículos";
    }
  }

  static String numberOfUsers(int count) {
    switch (locale) {
      case LC.en:
        return "$count Users";
      case LC.es:
        return "$count Usuarias";
    }
  }

  static String get today {
    switch (locale) {
      case LC.en:
        return "Today";
      case LC.es:
        return "Este Dia";
    }
  }

  static String get yesterday {
    switch (locale) {
      case LC.en:
        return "Yesterday";
      case LC.es:
        return "El Dia De Ayer";
    }
  }

  static String get last {
    switch (locale) {
      case LC.en:
        return "Last";
      case LC.es:
        return "Pasado";
    }
  }

  static String get minute {
    switch (locale) {
      case LC.en:
        return "m";
      case LC.es:
        return "m"; // minuto
    }
  }

  static String get hour {
    switch (locale) {
      case LC.en:
        return "h";
      case LC.es:
        return "h"; // hora
    }
  }

  static String get day {
    switch (locale) {
      case LC.en:
        return "d";
      case LC.es:
        return "d"; // dia
    }
  }

  static String get month {
    switch (locale) {
      case LC.en:
        return "mon";
      case LC.es:
        return "mes"; // mes
    }
  }

  static String get year {
    switch (locale) {
      case LC.en:
        return "y";
      case LC.es:
        return "a"; // ano
    }
  }
}

abstract class TRFlag {
  static String get rationalDescription {
    switch (locale) {
      case LC.en:
        return "Please provide a detailed description of why the content violates the community guidelines";
      case LC.es:
        return "Proporcione una descripción detallada de por qué el contenido infringe las normas de la comunidad.";
    }
  }

  static String get rational {
    switch (locale) {
      case LC.en:
        return "Rational";
      case LC.es:
        return "Racional";
    }
  }

  static String get reportContent {
    switch (locale) {
      case LC.en:
        return "Report Content";
      case LC.es:
        return "Reportar contenido";
    }
  }

  static String get flaggedContentMessage {
    switch (locale) {
      case LC.en:
        return "Content was flagged multiple times. Tap to show content.";
      case LC.es:
        return "El contenido se marcó varias veces. Toque para mostrar contenido.";
    }
  }
}

abstract class TRPurchaseCredit {
  TRPurchaseCredit._();

  static String get unableToConnect {
    switch (locale) {
      case LC.en:
        return "Unable to Connect to Store";
      case LC.es:
        return "No Se Puede Conectar a La Tienda";
    }
  }

  static String get purchaseCredits {
    switch (locale) {
      case LC.en:
        return "Purchase Credits";
      case LC.es:
        return "Comprar Créditos";
    }
  }
}

abstract class TRVoteWidget {
  TRVoteWidget._();

  static String get promotePost {
    switch (locale) {
      case LC.en:
        return "Promote Post";
      case LC.es:
        return "Promocionar Publicación";
    }
  }

  static String get promoteReview {
    switch (locale) {
      case LC.en:
        return "Promote Critique";
      case LC.es:
        return "Promover La Crítica";
    }
  }

  static String get promoteComment {
    switch (locale) {
      case LC.en:
        return "Promote Comment";
      case LC.es:
        return "Promocionar Comentario";
    }
  }

  static String get demotePost {
    switch (locale) {
      case LC.en:
        return "Demote Post";
      case LC.es:
        return "Degradar Publicación";
    }
  }

  static String get demoteReview {
    switch (locale) {
      case LC.en:
        return "Demote Critique";
      case LC.es:
        return "Degradar Crítica";
    }
  }

  static String get demoteComment {
    switch (locale) {
      case LC.en:
        return "Demote Comment";
      case LC.es:
        return "Degradar Comentario";
    }
  }

  static String get promotionAmount {
    switch (locale) {
      case LC.en:
        return "Promotion Amount";
      case LC.es:
        return "Importe De La Promoción";
    }
  }

  static String get demotionAmount {
    switch (locale) {
      case LC.en:
        return "Demotion Amount";
      case LC.es:
        return "Cantidad De Degradación";
    }
  }

  static String get creditsAvailable {
    switch (locale) {
      case LC.en:
        return "Credits Available";
      case LC.es:
        return "Créditos Disponibles";
    }
  }
}

abstract class TRFilterWidget {
  TRFilterWidget._();

  static String get from {
    switch (locale) {
      case LC.en:
        return "De";
      case LC.es:
        return "Créditos Disponibles";
    }
  }

  static String get to {
    switch (locale) {
      case LC.en:
        return "A";
      case LC.es:
        return "Créditos Disponibles";
    }
  }

  static String get selectDates {
    switch (locale) {
      case LC.en:
        return "Select Date Range";
      case LC.es:
        return "Seleccionar Rango De Fechas";
    }
  }

  static String get sortBy {
    switch (locale) {
      case LC.en:
        return "Sort BY";
      case LC.es:
        return "Ordenar Por";
    }
  }

  static String get categories {
    switch (locale) {
      case LC.en:
        return "Categories";
      case LC.es:
        return "Categorías";
    }
  }
}

abstract class TRFlagReason {
  static String get sexual {
    switch (locale) {
      case LC.en:
        return "Sexual Content";
      case LC.es:
        return "contenido sexual";
    }
  }

  static String get violent {
    switch (locale) {
      case LC.en:
        return "Violent Content";
      case LC.es:
        return "Contenido Violento";
    }
  }

  static String get hateful {
    switch (locale) {
      case LC.en:
        return "Hateful Content";
      case LC.es:
        return "Contenido Odioso";
    }
  }

  static String get harrasment {
    switch (locale) {
      case LC.en:
        return "Harassing Content";
      case LC.es:
        return "Contenido Acosador";
    }
  }

  static String get harmful {
    switch (locale) {
      case LC.en:
        return "Harmful Content";
      case LC.es:
        return "Contenido Dañino";
    }
  }

  static String get abusive {
    switch (locale) {
      case LC.en:
        return "Abusive Content";
      case LC.es:
        return "Contenido Abusivo";
    }
  }

  static String get spam {
    switch (locale) {
      case LC.en:
        return "Spam";
      case LC.es:
        return "Correo No Deseado";
    }
  }

  static String get other {
    switch (locale) {
      case LC.en:
        return "Other";
      case LC.es:
        return "Otra";
    }
  }
}

abstract class TRError {
  TRError._();

  static String get unknown {
    switch (locale) {
      case LC.en:
        return "An unknown error has occurred";
      case LC.es:
        return "Un error desconocido a ocurrido";
    }
  }

  static String get notSignedIn {
    switch (locale) {
      case LC.en:
        return "No user appears to be signed in";
      case LC.es:
        return "Ninguna usuario parece haber iniciado sesión";
    }
  }

  static String get tooLong {
    switch (locale) {
      case LC.en:
        return "Message length too long";
      case LC.es:
        return "Longitud del mensaje demasiado larga";
    }
  }

  static String get notValidated {
    // TODO: Show button for resending validation link
    switch (locale) {
      case LC.en:
        return "Your email is not validated. Please confirm by clicking the 'validate' link sent to your email";
      case LC.es:
        return "Su correo electrónico no está validado. Confirme haciendo clic en el enlace 'validar' enviado a su correo electrónico";
    }
  }
}

abstract class TRPreviewPosts {
  TRPreviewPosts._();

  static String get posted {
    switch (locale) {
      case LC.en:
        return "Posted";
      case LC.es:
        return "Al Corriente";
    }
  }

  static String get commented {
    switch (locale) {
      case LC.en:
        return "Commented";
      case LC.es:
        return "Comentada";
    }
  }

  static String get updatedPost {
    switch (locale) {
      case LC.en:
        return "Updated Post";
      case LC.es:
        return "Publicación Actualizada";
    }
  }

  static String get updatedComment {
    switch (locale) {
      case LC.en:
        return "Updated Comment";
      case LC.es:
        return "Comentario Actualizado";
    }
  }
}

enum LC { en, es }

LC get locale {
  final locale = Get.deviceLocale;
  final lang = locale?.languageCode ?? "en";
  switch (lang) {
    case "en":
      return LC.en;
    case "es":
      return LC.es;
    default:
      return LC.en;
  }
}

extension TitleCase on String {
  String get toTitleCase {
    return toBeginningOfSentenceCase(this) ?? this;
  }
}
