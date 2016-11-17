      SUBROUTINE TRAVEL(NZERO,NCOL,NROW,JCOL,JROW,NDIR,&
      IARRAY,JARRAY,E,N,ECG,NCG,gridspec)

! -- Subroutine travel finds part of a grid zone boundary.

! -- Revision history:-
!       July, 1993: version 1.
!       August, 1995: modified for inclusion in Groundwater Data Utilities.

	use defn
	use inter

      INTEGER*4 JCOL,JROW,NDIR,NCOL,NROW,NZERO,JR,JC
      INTEGER*4 IARRAY(NCOL,NROW),JARRAY(NCOL,NROW)
      REAL*4 E,N
      REAL*4 ECG(NCOL,NROW),NCG(NCOL,NROW)
	type(modelgrid) gridspec

      NZERO=0
      GO TO (100, 200, 300, 400) NDIR

  100 JR=JROW-1
      IF(JR.LT.1)THEN
	IF(IARRAY(JCOL,JROW).EQ.0)THEN
	   NZERO=1
	   RETURN
	END IF
	NDIR=2
	CALL CORNER(1,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
      IF(JCOL.EQ.1) GO TO 150
      IF((IARRAY(JCOL-1,JR).EQ.IARRAY(JCOL,JR))&
      .AND.(IARRAY(JCOL,JR).EQ.IARRAY(JCOL,JROW))) THEN
	NDIR=4
	JROW=JR
	JARRAY(JCOL,JROW)=1
	CALL CORNER(3,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
  150 IF(IARRAY(JCOL,JR).NE.IARRAY(JCOL,JROW))THEN
	NDIR=2
	CALL CORNER(1,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
      JROW=JR
      JARRAY(JCOL,JROW)=1
      GO TO 100

  200 JC=JCOL+1
      IF(JC.GT.NCOL) THEN
	IF(IARRAY(JCOL,JROW).EQ.0)THEN
	  NZERO=1
	  RETURN
	END IF
	NDIR=3
	CALL CORNER(2,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
      IF(JROW.EQ.1) GO TO 250
      IF((IARRAY(JC,JROW-1).EQ.IARRAY(JC,JROW))&
      .AND.(IARRAY(JC,JROW).EQ.IARRAY(JCOL,JROW)))THEN
	NDIR=1
	JCOL=JC
	JARRAY(JCOL,JROW)=1
	CALL CORNER(1,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
  250 IF(IARRAY(JC,JROW).NE.IARRAY(JCOL,JROW))THEN
	NDIR=3
	CALL CORNER(2,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
      JCOL=JC
      JARRAY(JCOL,JROW)=1
      GO TO 200

  300 JR=JROW+1
      IF(JR.GT.NROW)THEN
	IF(IARRAY(JCOL,JROW).EQ.0) THEN
	  NZERO=1
	  RETURN
	END IF
	NDIR=4
	CALL CORNER(4,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
      IF(JCOL.EQ.NCOL) GO TO 350
      IF((IARRAY(JCOL,JR).EQ.IARRAY(JCOL+1,JR)) &
      .AND.(IARRAY(JCOL,JR).EQ.IARRAY(JCOL,JROW))) THEN
	NDIR=2
	JROW=JR
	JARRAY(JCOL,JROW)=1
	CALL CORNER(2,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
  350 IF(IARRAY(JCOL,JR).NE.IARRAY(JCOL,JROW))THEN
	NDIR=4
	CALL CORNER(4,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
      JROW=JR
      JARRAY(JCOL,JROW)=1
      GO TO 300

  400 JC=JCOL-1
      IF(JC.LT.1)THEN
	IF(IARRAY(JCOL,JROW).EQ.0) THEN
	  NZERO=1
	  RETURN
	END IF
	NDIR=1
	CALL CORNER(3,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
      IF(JROW.EQ.NROW) GO TO 450
      IF((IARRAY(JC,JROW).EQ.IARRAY(JC,JROW+1)) &
      .AND.(IARRAY(JC,JROW).EQ.IARRAY(JCOL,JROW)))THEN
	NDIR=3
	JCOL=JC
	JARRAY(JCOL,JROW)=1
	CALL CORNER(4,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF
  450 IF(IARRAY(JC,JROW).NE.IARRAY(JCOL,JROW))THEN
	NDIR=1
	CALL CORNER(3,E,N,JCOL,JROW,gridspec,ECG,NCG)
	RETURN
      END IF    
      JCOL=JC
      JARRAY(JCOL,JROW)=1
      GO TO 400

      END
 