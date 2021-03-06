!     Last change:  JD    9 May 2003   11:54 am
program smptrend

! -- Program SMPTREND writes a "sample trend file" (in site sample file
!    format) based on data residing in an existing ASCII or binary bore/site
!    sample file.

! -- Program SMPTRENDS writes a "sample difference" file based on yearly sample trends.

	use defn
	use inter
	implicit none

        logical              :: lexist,active
        integer              :: ifail,idate,itry,inunit,ierr,ibore,j,nbb,i, &
                                iline,cols,ndays,nsecs,itemp, &
                                dd,mm,yy,hhh,mmm,sss,iheader,outunit,day1,day2, &
                                oldyear,year,yeardone,day,mon,nd,refunit,nref,ii
        integer, allocatable :: icheck(:)

	double precision     :: value,oldvalue,dtemp,initvalue,refvalue
        double precision, allocatable :: refval(:)

        character (len=1)    :: aa,bb,ayn,add
	character (len=5)    :: anum
        character (len=12)   :: siteid,oldsiteid
        character (len=15)   :: aline
        character (len=23)   :: bcode
	character (len=200)  :: infile,outfile,refvalfile,afile
        character (len=10), allocatable :: rbore(:)


	write(amessage,5)
5	format(' Program SMPTREND writes a "sample trend file" (in bore sample file ', &
        'format) based on data residing in an existing bore sample file.')
	call write_message(leadspace='yes',endspace='yes')

	call read_settings(ifail,idate,iheader)
	if(ifail.eq.1) then
	  write(amessage,7)
7	  format(' A settings file (settings.fig) was not found in the ', &
	  'current directory.')
	  call write_message
	  go to 9900
	else if(ifail.eq.2) then
	  write(amessage,8)
8	  format(' Error encountered while reading settings file settings.fig')
	  call write_message
	  go to 9900
	endif
	if((idate.ne.0).or.(datespec.eq.0)) then
	  write(amessage,9)
9	  format(' Cannot read date format from settings file ', &
	  'settings.fig')
	  call write_message
	  go to 9900
	end if

        ayn='y'
21      itry=0
22      continue
        if(itry.gt.5) go to 9900
19      write(6,23,advance='no')
23      format(' Enter name of existing bore sample file: ')
        read(5,'(a)') infile
        if(infile.eq.' ') go to 19
        if(index(eschar,infile(1:2)).ne.0) then
          go to 9900
        end if
        nbb=len_trim(infile)
        call getfile(ifail,infile,afile,1,nbb)
        if(ifail.ne.0) go to 19
        infile=afile
        inquire(file=infile,exist=lexist)
        if(.not.lexist)then
          write(amessage,28) trim(infile)
28        format(' File ',a,' does not exist - try again.')
          call write_message()
          itry=itry+1
          go to 22
        end if
!31      write(6,32,advance='no')
!32      format(' Is this an ASCII or binary file?  [a/b]: ')
!        read(5,'(a)') aa
!        if(aa.eq.' ') go to 31
!        if((aa.eq.'e').or.(aa.eq.'E')) then
!          write(6,*)
!          go to 21
!        end if
!        if((aa.eq.'A').or.(aa.eq.'a'))then
          aa='a'
!        else if((aa.eq.'B').or.(aa.eq.'b'))then
!          aa='b'
!        else
!          go to 31
!        end if
        inunit=nextunit()
        if(aa.eq.'a')then
          open(unit=inunit,file=infile,form='formatted',status='old',   &
          iostat=ierr)
          if(ierr.ne.0)then
            write(amessage,29)
29          format(' Cannot open file ',a,'. Is this file an ASCII file? ', &
            'Is it being used by another program?')
            call write_message(leadspace='yes',endspace='yes')
            itry=itry+1
            go to 22
          end if
        else
          open(unit=inunit,file=infile,form='binary',status='old',   &
          iostat=ierr)
          if(ierr.ne.0)then
            write(amessage,39)
39          format(' Cannot open file ',a,'. Is this file truly a binary file? ', &
            'Is it being used by another program?')
            call write_message(leadspace='yes',endspace='yes')
            itry=itry+1
            go to 22
          end if
          read(inunit,iostat=ierr) bcode
          if(ierr.ne.0)then
            write(amessage,42) trim(infile)
42          format(' Cannot read header to binary site sample file ',a,  &
            ': are you sure that this is a file of the correct type? Try again.')
            call write_message(leadspace='yes',endspace='yes')
            itry=itry+1
            close(unit=inunit)
            go to 22
          end if
          if(bcode.ne.'binary_site_sample_file')then
            write(amessage,45) trim(infile)
45          format(' Incorrect header to file ',a,': are you sure that this is a ', &
            'binary site sample file? Try again.')
            call write_message(leadspace='yes',endspace='yes')
            itry=itry+1
            close(unit=inunit)
            go to 22
          end if
        end if
        write(6,*)

100     call read_bore_list_file(ifail, &
       ' Enter name of bore listing file: ',coord_check='no')
	if(ifail.ne.0) go to 9900
	if(escset.ne.0) then
	  escset=0
	  write(6,*)
          close(unit=inunit)
	  go to 22
	end if
        allocate(icheck(num_bore_list),stat=ierr)
        if(ierr.ne.0)then
          write(amessage,101)
101       format(' Cannot allocate sufficient memory to continue execution.')
          go to 9890
        end if
        icheck=0

        if(num_bore_list.gt.1)then
          do i=1,num_bore_list
            do j=i+1,num_bore_list
              if(bore_list_id(i).eq.bore_list_id(j))then
                write(amessage,102) trim(bore_list_id(i))
102             format(' Duplicate bore identifiers "',a,'" provided in bore listing file.')
                go to 9890
              end if
            end do
          end do
        end if

        write(6,*)
49      itry=0
50      continue
        if(itry.gt.5) go to 9900
        write(6,60,advance='no')
60      format(' Enter name for new bore sample file: ')
        read(5,'(a)') outfile
        if(index(eschar,outfile(1:2)).ne.0) then
          deallocate(icheck,stat=ierr)
          write(6,*)
          go to 100
        end if
        nbb=len_trim(outfile)
        call getfile(ifail,outfile,afile,1,nbb)
        if(ifail.ne.0) go to 50
        outfile=afile
        outunit=nextunit()
!61      write(6,32,advance='no')
!        read(5,'(a)') bb
!        if(bb.eq.' ') go to 61
!        if((bb.eq.'e').or.(bb.eq.'E')) then
!          write(6,*)
!          go to 49
!        end if
!        if((bb.eq.'A').or.(bb.eq.'a'))then
          bb='a'
!        else if((bb.eq.'B').or.(bb.eq.'b'))then
!          bb='b'
!        else
!          go to 61
!        end if
        if(bb.eq.'b')then
          open(unit=outunit,file=outfile,form='binary', &
          iostat=ierr)
          if(ierr.ne.0)then
            write(amessage,70) trim(outfile)
70          format(' Cannot open file ',a,' for output. Try again.')
            call write_message(leadspace='yes',endspace='yes')
            itry=itry+1
            go to 50
          end if
          write(outunit) 'binary_site_sample_file'
        else
          open(unit=outunit,file=outfile,iostat=ierr)
          if(ierr.ne.0)then
            write(amessage,70) trim(outfile)
            call write_message(leadspace='yes',endspace='yes')
            itry=itry+1
            go to 50
          end if
        end if

! -- The time window for trend sampling is now defined.

        write(6,*)
400     write(6,410,advance='no')
410     format(' Enter opening day of year for trend sampling [days]: ')
	itemp=key_read(day1)
	if(escset.ne.0)then
	  escset=0
          close(unit=outunit)
          write(6,*)
          go to 49
	else if(itemp.eq.-1) then
	  go to 400
	else if(itemp.ne.0) then
	  write(6,420)
420	  format(' Illegal input  - try again.')
	  go to 400
	end if
        if((day1.le.0).or.(day1.gt.365))then
          write(6,421)
421       format(' Out of range - try again.')
          go to 400
        end if

430     write(6,440,advance='no')
440     format(' Enter closing day of year for trend sampling [days]: ')
	itemp=key_read(day2)
	if(escset.ne.0)then
	  escset=0
          write(6,*)
          go to 400
	else if(itemp.eq.-1) then
	  go to 430
	else if(itemp.ne.0) then
	  write(6,420)
	  go to 430
	end if
        if((day2.le.0).or.(day2.gt.365))then
          write(6,421)
          go to 430
        end if
        if(day2.le.day1)then
          write(6,422)
422       format(' Second day must exceed first day - try again.')
          go to 430
        end if

71      write(6,72,advance='no')
72      format(' Difference wrt to first or reference sample?  [f/r]: ')
        read(5,'(a)') add
        if(add.eq.' ') go to 71
        if((add.eq.'e').or.(add.eq.'E')) then
          write(6,*)
          go to 430
        end if
        if ((add.eq.'F').or.(add.eq.'f'))then
          add='f'
        else if((add.eq.'R').or.(add.eq.'r'))then
          add='r'
        else
          go to 71
        end if

        if(add.eq.'f')then
80        write(6,82,advance='no')
82        format(' Retain initial trend sample for each bore in output file?  [y/n]: ')
          read(5,'(a)') ayn
          if(ayn.eq.' ') go to 80
          if((ayn.eq.'e').or.(ayn.eq.'E')) then
            write(6,*)
            go to 71
          end if
          if((ayn.eq.'N').or.(ayn.eq.'n'))then
            ayn='n'
          else if((ayn.eq.'Y').or.(ayn.eq.'y'))then
            ayn='y'
          else
            go to 80
          end if
        end if

! -- The reference value file is read if necessary.

        if(add.eq.'r')then
700       write(6,710,advance='no')
710       format(' Enter name of reference value file: ')
          read(5,'(a)') refvalfile
          if(refvalfile.eq.' ') go to 700
          refvalfile=adjustl(refvalfile)
          if((refvalfile(1:2).eq.'E ').or.(refvalfile(1:2).eq.'e '))then
            write(6,*)
            go to 71
          end if
          nbb=len_trim(refvalfile)
          call getfile(ifail,refvalfile,afile,1,nbb)
          if(ifail.ne.0) go to 700
          refvalfile=afile
          refunit=nextunit()
          open(unit=refunit,file=refvalfile,status='old',iostat=ierr)
          if(ierr.ne.0)then
            write(6,715) trim(refvalfile)
715         format(' Cannot open file ',a,' - try again.')
            go to 700
          end if
          iline=0
          do
            iline=iline+1
            read(refunit,'(a)',err=9000,end=730)
          end do
730       allocate(rbore(iline),refval(iline),stat=ierr)
          if(ierr.ne.0)then
            write(amessage,101)
            go to 9890
          end if
          rewind(unit=refunit)
          nref=0
          iline=0
          do
            iline=iline+1
            read(refunit,'(a)',err=9000,end=800) cline
            if(cline.eq.' ') cycle
            call linesplit(ifail,2)
            if(ifail.ne.0)then
              call num2char(iline,aline)
              write(amessage,740) trim(aline),trim(refvalfile)
740           format(' Insufficient entries on line ',a,' of file ',a)
              go to 9890
            end if
            nref=nref+1
            rbore(nref)=cline(left_word(1):right_word(1))
            call casetrans(rbore(nref),'hi')
            refval(nref)=char2real(ifail,2)
            if(ifail.ne.0)then
              call num2char(iline,aline)
              write(amessage,750) trim(aline),trim(refvalfile)
750           format(' Cannot read reference value from line ',a,' of file ',a,'.')
              go to 9890
            end if
          end do
800       close(unit=refunit)
          write(6,*)
          write(6,510) trim(refvalfile)
        end if

! -- The output file is now written.

        oldsiteid=' '
        iline=0
        read_smp_file: do
          iline=iline+1
          if(aa.eq.'a')then
	    read(inunit,'(a)',end=500) cline
	    cols=5
	    call linesplit(ifail,5)
	    if(ifail.lt.0) cycle read_smp_file
	    if(ifail.gt.0)then
	      cols=4
	      call linesplit(ifail,4)
	      if(ifail.ne.0) then
	        call num2char(iline,aline)
	        write(amessage,150) trim(aline),trim(infile)
150             format(' Insufficient entries on line ',a,' of bore sample file ',a)
	        go to 9890
	      end if
	    end if
	    siteid=cline(left_word(1):right_word(1))
	    call casetrans(siteid,'hi')
          else
	    read(inunit,end=500,iostat=ierr) siteid,ndays,nsecs,value
            if(ierr.ne.0)then
              call num2char(iline,aline)
              write(amessage,160) trim(aline),trim(infile)
160           format(' Cannot read record ',a,' of bore sample file ',a)
              go to 9890
            end if
	    call casetrans(siteid,'hi')
          end if
          if(siteid.eq.oldsiteid)then
            if(.not.active) cycle read_smp_file
          else
            oldsiteid=siteid
            active=.false.
            initvalue=-1.1e35
            oldyear=-9999
            year=-9999
            yeardone=-1
            do ibore=1,num_bore_list
              if(siteid.eq.bore_list_id(ibore)) go to 190
            end do
            cycle read_smp_file
190         continue
            active=.true.
            if(add.eq.'r')then
              do ii=1,nref
                if(rbore(ii).eq.siteid) go to 195
              end do
              write(amessage,193) trim(siteid)
193           format(' Bore "',a,'" is listed in site sample file but not in ',  &
              'reference value file.')
              go to 9890
195           refvalue=refval(ii)
            end if
          end if
          if(aa.eq.'a')then
            call read_rest_of_sample_line(ifail,cols,ndays,nsecs,value, &
            iline,infile)
            if(ifail.ne.0) go to 9900
            if(value.lt.-1.0e38) cycle read_smp_file
          end if
          oldyear=year
	  call newdate(ndays,1,1,1970,day,mon,year)
          if(year.ne.oldyear) yeardone=0
          if(yeardone.eq.1) then
            cycle read_smp_file
          else
            nd=numdays(1,1,year,day,mon,year)
            if((nd.lt.day1).or.(nd.gt.day2))cycle read_smp_file
            yeardone=1
            if(initvalue.lt.-1.0e35)then
              initvalue=value
              if(ayn.eq.'n') cycle read_smp_file
              if(add.eq.'f')then
                dtemp=value
              else if(add.eq.'r')then
                dtemp=value-refvalue
              end if
            else
              if(add.eq.'f')then
                dtemp=value-initvalue
              else
                dtemp=value-refvalue
              end if
              icheck(ibore)=1
            end if
            if(bb.eq.'a')then
              dd=day
              mm=mon
              yy=year
	      hhh=nsecs/3600
	      mmm=(nsecs-hhh*3600)/60
	      sss=nsecs-hhh*3600-mmm*60
	      if(datespec.eq.1) then
	        write(outunit,170) trim(siteid),dd,mm,yy,hhh,mmm,sss,dtemp
170	        format(1x,a,t15,i2.2,'/',i2.2,'/',i4.4,3x,i2.2,':',i2.2,':',   &
	        i2.2,3x,1pg15.8)
	      else
	        write(outunit,170) trim(siteid),mm,dd,yy,hhh,mmm,sss,dtemp
	      endif
            else
              write(outunit)siteid,ndays,nsecs,dtemp
            end if
          end if
        end do read_smp_file

500     continue
        write(6,510) trim(infile)
510     format(' - file ',a,' read ok.')
        write(6,520) trim(outfile)
520     format(' - file ',a,' written ok.')

        if(any(icheck.eq.0))then
          write(amessage,540)
540       format(' Warning: trend values could not be calculated for at least the following ', &
          'bores from the bore listing file. Either the bores are not present in ',  &
          'the site sample file, or have not been sampled more than once within ', &
          'the trend sampling window:-')
          call write_message(leadspace='yes')
	  amessage=' '
          j=4
          imessage=0
          write_bores_1: do ibore=1,num_bore_list
            if(icheck(ibore).eq.0) then
              write(amessage(j:),'(a)') trim(bore_list_id(ibore))
              j=j+11
              if(j.ge.69) then
                call write_message(increment=1)
                if(imessage.gt.18) goto 9900
                j=4
              end if
            end if
          end do write_bores_1
          if(j.ne.4) call write_message
        end if

        go to 9900

9000    call num2char(iline,aline)
        write(amessage,9010) trim(aline),trim(refvalfile)
9010    format(' Error reading line ',a,' of file ',a)
        go to 9890

9890    call write_message(leadspace='yes')
9900    call close_files
        call free_bore_mem()
        deallocate(icheck,stat=ierr)
        write(6,*)

end program smptrend

