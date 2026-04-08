#include "my_application.h"
#include <locale.h>

int main(int argc, char** argv) {
  setenv("LC_ALL", "C", 1);
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
