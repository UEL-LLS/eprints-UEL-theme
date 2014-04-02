$c->{theme} = 'roar';

# Delete as appropriate to allow correct colours to be displayed
#$c->{uelbranding}{repo} = "ROAR";
#$c->{uelbranding}{repo} = "DATA";

#### overide eprint_render

$c->{original_eprint_render} = $c->{eprint_render};

$c->{eprint_render} = sub {

    my ($eprint, $repository, $preview) = @_;
    
    #if($eprint->value("type") ne "data_collection"){
    #        return $repository->call("original_eprint_render", $eprint, $repository, $preview);
    #     }

    my $succeeds_field   = $repository->dataset("eprint")->field("succeeds");
    my $commentary_field = $repository->dataset("eprint")->field("commentary");

    my $flags = {
                 has_multiple_versions => $eprint->in_thread($succeeds_field),
                 in_commentary_thread  => $eprint->in_thread($commentary_field),
                 preview               => $preview,
                };

    my %fragments = ();

    # Put in a message describing how this document has other versions
    # in the repository if appropriate
    if ($flags->{has_multiple_versions})
    {
        my $latest = $eprint->last_in_thread($succeeds_field);

        #my @rdfiles;
        if ($latest->value("eprintid") == $eprint->value("eprintid"))
        {
            $flags->{latest_version} = 1;
            $fragments{multi_info} =
              $repository->html_phrase("page:latest_version");
        } ## end if ($latest->value("eprintid"...))
        else
        {
            $fragments{multi_info} =
              $repository->render_message(
                        "warning",
                        $repository->html_phrase(
                            "page:not_latest_version",
                            link => $repository->render_link($latest->get_url())
                        )
              );
        } ## end else [ if ($latest->value("eprintid"...))]
    } ## end if ($flags->{has_multiple_versions...})

    # Now show the version and commentary response threads
    if ($flags->{has_multiple_versions})
    {
        $fragments{version_tree} =
          $eprint->render_version_thread($succeeds_field);
    }

    if ($flags->{in_commentary_thread})
    {
        $fragments{commentary_tree} =
          $eprint->render_version_thread($commentary_field);
    }

    if (0)
    {

        # Experimental SFX Link
        my $authors      = $eprint->value("creators");
        my $first_author = $authors->[0];
        my $url          = "http://demo.exlibrisgroup.com:9003/demo?";

        #my $url = "http://aire.cab.unipd.it:9003/unipr?";
        $url .= "title=" . $eprint->value("title");
        $url .= "&aulast=" . $first_author->{name}->{family};
        $url .= "&aufirst=" . $first_author->{name}->{family};
        $url .= "&date=" . $eprint->value("date");
        $fragments{sfx_url} = $url;
    } ## end if (0)

    if (0)
    {

        # Experimental OVID Link
        my $authors      = $eprint->value("creators");
        my $first_author = $authors->[0];
        my $url          = "http://linksolver.ovid.com/OpenUrl/LinkSolver?";
        $url .= "atitle=" . $eprint->value("title");
        $url .= "&aulast=" . $first_author->{name}->{family};
        $url .= "&date=" . substr($eprint->value("date"), 0, 4);
        if ($eprint->is_set("issn"))
        {
            $url .= "&issn=" . $eprint->value("issn");
        }
        if ($eprint->is_set("volume"))
        {
            $url .= "&volume=" . $eprint->value("volume");
        }
        if ($eprint->is_set("number"))
        {
            $url .= "&issue=" . $eprint->value("number");
        }
        if ($eprint->is_set("pagerange"))
        {
            my $pr = $eprint->value("pagerange");
            $pr =~ m/^([^-]+)-/;
            $url .= "&spage=$1";
        } ## end if ($eprint->is_set("pagerange"...))
        $fragments{ovid_url} = $url;
    } ## end if (0)

##########
    #
    #
    ##rd essex
    #
    #
##########
    if($eprint->value("type") ne "data_collection"){
         #   return $repository->call("original_eprint_render", $eprint, $repository, $preview);
	 foreach my $key ( keys %fragments ) { $fragments{$key} = [ $fragments{$key}, "XHTML" ]; }

        my $page = $eprint->render_citation( "uel_summary_page", %fragments, flags=>$flags );

        my $title = $eprint->render_citation("brief");

        my $links = $repository->xml()->create_document_fragment();
        if( !$preview )
        {
                $links->appendChild( $repository->plugin( "Export::Simple" )->dataobj_to_html_header( $eprint ) );
                $links->appendChild( $repository->plugin( "Export::DC" )->dataobj_to_html_header( $eprint ) );
        }

        return( $page, $title, $links );
    }


    #add rdessex div to append file content to
    my $div_right =
      $repository->make_element('div', class => "rd_citation_right");

    #add rdessex doc frag to add content to
    my $rddocsfrag = $repository->make_doc_fragment;

    #Add main Available Files h2 heading
    #Check if there are docs to display, if not print No files to display

    my $heading = $repository->make_element('h2', class => "file_list_heading");
    $heading->appendChild($repository->make_text(" Available Files"));
    $rddocsfrag->appendChild($heading);

    if (scalar( $eprint->get_all_documents() ) eq 0)
    {

        my $nodocs =
          $repository->make_element('p', class => "file_list_nodocs");
        $nodocs->appendChild($repository->make_text(" No Files to display"));
        $rddocsfrag->appendChild($nodocs);

    } ## end if ($doc_check eq 0)

    # add hashref to store our content types and associated files
    my $rdfiles = {};

    #get all documents from the eprint, then loop through and add each content type and associated files as a hash key and an array of values
    foreach my $rddoc ($eprint->get_all_documents())

    {

        my $content = $rddoc->get_value("content");
        {
            if (defined($content) && $content eq "full_archive")
            {
                push @{$rdfiles->{"rdarchive"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "data")
            {
                push @{$rdfiles->{"rddata"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "documentation")
            {
                push @{$rdfiles->{"rddocu"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "readme")
            {
                push @{$rdfiles->{"rdreadme"}}, $rddoc;
            }
            elsif (defined($content) && $content eq "depmeta")
            {
                push @{$rdfiles->{"rddepmeta"}}, $rddoc;
            }

        }
    } ## end foreach my $rddoc ($eprint->get_all_documents...)

    # add a list of constants to generate our headings
    my $list = {

        "rdarchive" => 'Full Archive',
        "rddata"    => 'Data',
        "rddocu"    => 'Documentation',
        "rdreadme"  => 'Read me',
        "rddepmeta" => 'Departmental metadata'

    };

    # loop through a list of content types adding a header if files exist in the array
    foreach my $content_type (qw/ rdarchive rddata rddocu rdreadme rddepmeta /)
    {
        next unless (defined $rdfiles->{$content_type});
        my $rdheading = $repository->make_element('h2', class => "file_title");
        $rdheading->appendChild($repository->make_text($list->{$content_type}));
        $rddocsfrag->appendChild($rdheading);

        #if files exist, add a table to hold the filenames

        #begin rd table
        my $rdtable =
          $repository->make_element(
                                    "table",
                                    border      => "0",
                                    cellpadding => "2",
                                    width       => "100%"
                                   );

        $rddocsfrag->appendChild($rdtable);

        #for each document add a table row
        foreach my $rdfile (@{$rdfiles->{$content_type}})

        {
            my $tr  = $repository->make_element('tr');
            my $tdr = $repository->make_element('td', class => 'files_box');
            my $trm = $repository->make_element('tr');
            $tr->appendChild($tdr);

            #get the url and render the filename as a link
            my $a = $repository->render_link($rdfile->get_url);

            my $filetmp =
              substr($rdfile->get_url, (rindex($rdfile->get_url, "/") + 1));

            #check the length of the url first,  if more that 30 chars truncate the middle
            my $len = 30;
            my $filetmp_trunc;
            if (length($filetmp) > $len)
            {
                $filetmp_trunc =
                    substr($filetmp, 0, $len / 2) . " ... "
                  . substr($filetmp, -$len / 2);
            } ## end if (length($filetmp) >...)
            else
            {
                $filetmp_trunc = $filetmp;
            }

            #generate a doc id for javascript to target
            my $docid      = $rdfile->get_id;
            my $doc_prefix = "_doc_" . $docid;

            #add filemeta div
            my $filemetadiv =
              $repository->make_element(
                                        'div',
                                        id    => $doc_prefix . '_filemetadiv',
                                        class => 'rd_full'
                                       );

            #Add table to hold filemeta
            my $filetable =
              $repository->make_element(
                                        "table",
                                        id          => "filemeta",
					class	=> "table",
                                        border      => "0",
                                        cellpadding => "2",
                                        width       => "100%"
                                       );

            #Render a row to hold the link to  extended metadata
            #If a value exists add a table row for each file metafield

            #check to see who should be able to access this document
            #if there's an embagro, print the date the doc becomes available
            #
            if (   (defined($rdfile->get_value("security"))) ne "public"
                && (defined($rdfile->get_value("date_embargo"))) ne "")
            {
                my $docavailable =
                  $repository->make_element('div', class => 'rd_doc_available',
                  );
                my $until       = $repository->make_text(' until ');
                my $dateembargo = $rdfile->render_value("date_embargo");
                my $security    = $rdfile->render_value("security");
                $docavailable->appendChild($security);
                $docavailable->appendChild($until);
                $docavailable->appendChild($dateembargo);
                $filetable->appendChild(
                    $repository->render_row(
                        $repository->html_phrase("document_fieldname_security"),
                        $docavailable
                    )
                );
            } ## end if ((defined($rdfile->get_value...)))
            else
            {

                $filetable->appendChild(
                    $repository->render_row(
                        $repository->html_phrase("document_fieldname_security"),
                        $rdfile->render_value("security")
                    )
                );
            } ## end else [ if ((defined($rdfile->get_value...)))]

            #
            # loop through the remaining document metadata and add a row of data for each -
            #
            #
            my @rd_filemeta_items =
              qw(content formatdesc rev_number mime_type license);

            # get the doc id to use as prefix on div ids

            foreach my $rd_filemeta_item (@rd_filemeta_items)
            {
                if (   $rdfile->is_set($rd_filemeta_item)
                    && $rd_filemeta_item eq "mime_type")
                {
                    $filetable->appendChild(
                        $repository->render_row(
                            $repository->html_phrase(
                                           "file_fieldname_" . $rd_filemeta_item
                            ),

                            #$rdfile->render_value($rd_filemeta_item_value)
                            $rdfile->render_value($rd_filemeta_item)
                                               )
                                           );
                } ## end if ($rdfile->is_set($rd_filemeta_item...))

                elsif ($rdfile->is_set($rd_filemeta_item))
                {
                    $filetable->appendChild(
                               $repository->render_row(
                                   $repository->html_phrase(
                                       "document_fieldname_" . $rd_filemeta_item
                                   ),
                                   $rdfile->render_value($rd_filemeta_item)
                               )
                    );
                } ## end elsif ($rdfile->is_set($rd_filemeta_item...))
            } ## end foreach my $rd_filemeta_item...

            # calculate the filesize of each file and print it
            if (defined($rdfile))
            {
                my %files         = $rdfile->files;
                my $size_in_bytes = ($files{$rdfile->get_main("filesize")});
                my $filesize = EPrints::Utils::human_filesize($size_in_bytes);

                {
                    $filetable->appendChild(
                        $repository->render_row(
                            $repository->html_phrase("file_fieldname_filesize"),
                            $repository->make_text($filesize)
                        )
                    );
                }
            } ## end if (defined($rdfile))

            #Append filetable to filemetadiv
            $filemetadiv->appendChild($filetable);

            #render our file name as a link element and append to the left-hand side of the table
            $a->appendChild($repository->make_text($filetmp_trunc));

            #render a collapsible box to house our filemeta table

            my ($self) = @_;

            my %options;
            $options{session}   = $self->{session};
            $options{id}        = $doc_prefix . "_file_meta";
            $options{title}     = $a;
            $options{content}   = $filemetadiv;
            $options{collapsed} = 1;
            my $filebox = EPrints::Box::render(%options);

            #Append filemetabox to our file table
            $tdr->appendChild($filebox);

            #Append whole row to table
            $rdtable->appendChild($tr);

        } ## end foreach my $rdfile (@{$rdfiles...})

    } ## end foreach my $content_type (...)

    #Append the whole fragment to div_right, then add div_right to the fragments hash to be sent to the dom
    $div_right->appendChild($rddocsfrag);
    $fragments{rd_sorteddocs} = $div_right;

    foreach my $key (keys %fragments)
    {
        $fragments{$key} = [$fragments{$key}, "XHTML"];
    }

    my $page = $eprint->render_citation("uel_summary_page_data", %fragments,
                                        flags => $flags);

    my $title = $eprint->render_citation("brief");
    my $links = $repository->xml()->create_document_fragment();
    if (!$preview)
    {
        $links->appendChild($repository->plugin("Export::Simple")
                            ->dataobj_to_html_header($eprint));
        $links->appendChild(
            $repository->plugin("Export::DC")->dataobj_to_html_header($eprint));
    } ## end if (!$preview)

    return ($page, $title, $links);
};
