AC_DEFUN([OMC_AC_LAPACK], [

  # Cannot use AX_LAPACK since it assumes a Fortran compiler is used
  AC_ARG_WITH(lapack,  [  --with-lapack=[auto] Use --with-lapack="-llapack -lblas", or let OMC auto-detect using pkg-config, etc.],
    [LD_LAPACK="$withval"],
    [LD_LAPACK="auto"])

  if test "$LD_LAPACK" = "no"; then
    FINAL_MESSAGES="$FINAL_MESSAGES\nLAPACK IS NOT AVAILABLE! ONLY USED FOR CROSS-COMPILING/BOOTSTRAPPING"
    LD_LAPACK=""
    NO_LAPACK="#define NO_LAPACK"
  else

    AC_LANG_PUSH([C])
    AC_MSG_CHECKING([LAPACK/BLAS flags])
    OLDLIBS="$LIBS"

    LAPACK_LINKER_FLAGS=""
    for flag in -Wl,--no-undefined; do
      LIBS="$LAPACK_LINKER_FLAGS $flag"
      AC_TRY_LINK([], [return 0;], [LAPACK_LINKER_FLAGS="$LIBS"],[])
    done
    LIBS=""

    if test "$LD_LAPACK" = "auto"; then
      LD_LAPACK=""
      if test "$1" = "static" || test "$2" = "static"; then
        PKGCONFIG="pkg-config --static --libs --silence-errors"
        LD_LAPACK_STATIC_HEAD="-Wl,-Bstatic"
        LD_LAPACK_STATIC_TAIL="-Wl,-Bdynamic"
      else
        PKGCONFIG="pkg-config --libs --silence-errors"
      fi
      for flags in "-lopenblas" "`$PKGCONFIG lapack`" "`$PKGCONFIG lapack blas`" "-llapack -lblas" "-llapack -lblas -lm -latlas"; do
        for extra in "" "-lgfortran" "-lgfortran -lquadmath"; do
          THESELIBS="$LD_LAPACK_STATIC_HEAD $flags $extra $LD_LAPACK_STATIC_TAIL"
          LIBS="-shared $THESELIBS $LAPACK_LINKER_FLAGS"
          AC_LINK_IFELSE([AC_LANG_CALL([], [dgesv_])],[
            AC_LINK_IFELSE([AC_LANG_CALL([], [dswap_])],[LD_LAPACK="$THESELIBS"],[])
          ],[])
          if test ! -z "$LD_LAPACK"; then
            break;
          fi
        done

        if test ! -z "$LD_LAPACK"; then
          break;
        fi

        for extra_dynamic in "-lm" "-lpthread" "-lm -lpthread"; do
          THESELIBS="$LD_LAPACK_STATIC_HEAD $flags $LD_LAPACK_STATIC_TAIL $extra_dynamic"
          LIBS="-shared $THESELIBS $LAPACK_LINKER_FLAGS"
          AC_LINK_IFELSE([AC_LANG_CALL([], [dgesv_])],[
            AC_LINK_IFELSE([AC_LANG_CALL([], [dswap_])],[LD_LAPACK="$THESELIBS"],[])
          ],[])
          if test ! -z "$LD_LAPACK"; then
            break;
          fi
        done

        if test ! -z "$LD_LAPACK"; then
          break;
        fi
      done
      if test -z "$LD_LAPACK"; then
        if test "$1" = "RequireFound"; then
          AC_MSG_ERROR([dgesv or dswap not found])
        else
          AC_MSG_RESULT([not found])
        fi
      else
        AC_MSG_RESULT([$LD_LAPACK])
      fi
    elif test ! -z "$LD_LAPACK"; then
      LIBS="$LD_LAPACK"
      AC_LINK_IFELSE([AC_LANG_CALL([], [dgesv_])],[],[
        if test "$1" = "RequireFound"; then
          AC_MSG_ERROR([dgesv (LAPACK) linking failed using $LD_LAPACK])
        else
          AC_MSG_RESULT([dgesv (LAPACK) linking failed using $LD_LAPACK]); LD_LAPACK=""
        fi
      ])
      AC_LINK_IFELSE([AC_LANG_CALL([], [dswap_])],[AC_MSG_RESULT([$LD_LAPACK])],[
        if test "$1" = "RequireFound"; then
          AC_MSG_ERROR([dgesv (BLAS) linking failed using $LD_LAPACK])
        else
          AC_MSG_RESULT([dgesv (BLAS) linking failed using $LD_LAPACK]); LD_LAPACK=""
        fi
      ])
    fi
    if test ! -z "$LD_LAPACK"; then
      # lapack 3.6.0 deprecated dgegv, dgelsx, dgeqpf
      AC_MSG_CHECKING([for deprecated LAPACK routines])
      AC_LINK_IFELSE([AC_LANG_CALL([], [dgegv_])],[AC_MSG_RESULT([yes]); NO_LAPACK="#define HAVE_LAPACK_DEPRECATED 1"],[
        AC_MSG_RESULT([no])
      ])
    fi
    LIBS="$OLDLIBS"
    AC_LANG_POP([C])
  fi
])
