export default class NavBar {

  constructor() {
    this.setActiveLink();
    this.fixNavBarOnScroll();
    this.fixNavbarOverlapInMobile();
  }

  fixNavBarOnScroll() {
    $(window).scroll(function () {
      const $body = $('body');
      const $navbar = $('.navbar');

      if ($(window).scrollTop() >= 65) {
        if (!$navbar.hasClass('navbar-fixed-top')) {
          $('header').css('visibility', 'hidden');
          $navbar.addClass('navbar-fixed-top');
          $('body').css('padding-top', '64px');
        }
      }
      else if ($(window).scrollTop() < 1) {
        $navbar.removeClass('navbar-fixed-top');
        $('header').css('visibility', 'visible');
        $('body').css('padding-top', '0px');
      }
    });
  }

  fixNavbarOverlapInMobile() {
    $("#js-navbar-button").on("click", ()  => {
      $('.navbar').addClass('navbar-fixed-top');
    });
  }

  setActiveLink() {
    $(".navbar__link, .navbar__dropdown__link").each(function() {
      var linkAddress = $(this).attr('href');
      var currentAddress = window.location.toString();

      if (currentAddress.indexOf(linkAddress) >= 0) {
        $(this).closest(".navbar__item").addClass('active');
      }
    });
  }
}
