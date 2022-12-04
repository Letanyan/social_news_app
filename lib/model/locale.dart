import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'helpers.dart';

class TRGeneral {
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
}

class TRSorting {
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

class TRHome {
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
        return "Added $amount Credit for daily login. Login again tomorrow for an additional $nextAmount credit from your streak.";
      case LC.es:
        return "Se agregó $amount crédito por inicio de sesión diario. Vuelva a iniciar sesión mañana para obtener $nextAmount crédito adicional de su racha.";
    }
  }

  static String get addCreditsAccept {
    switch (locale) {
      case LC.en:
        return "Got It";
      case LC.es:
        return "Entiendo";
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
