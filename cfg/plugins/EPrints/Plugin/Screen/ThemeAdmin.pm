package EPrints::Plugin::Screen::ThemeAdmin;

use EPrints::Plugin::Screen;

@ISA = ( 'EPrints::Plugin::Screen' );


use Data::Dumper;
use EPrints::Plugin::Screen::Admin::Phrases;
use feature qw(switch say);
use strict;
use warnings;
sub new 
{
	my( $class, %params ) = @_;
	my $self = $class->SUPER::new(%params);


	$self->{actions}= [qw/ update_theme /];

	$self->{priv} = undef;
	$self->{appears} = [
		{ 
			place => "admin_actions_config",
			position => 2800, 
		},
	];
	return $self;
}

sub can_be_viewed
{
	my( $self ) = @_;
	return $self->allow( "config/edit/perl" );
}


sub get_themes
{
	my( $self ) = @_;
	my $session = $self->{session};
	my @themes;
        my $dir = $session->config( "config_path" )."/themes/";

    	opendir(DIR, $dir) or die $!;

    	while (my $file = readdir(DIR)) {

        	# Use a regular expression to ignore files beginning with a period
        	next if ($file =~ m/^\./);
		push (@themes, $file);
        	#print "$file\n";

    	}

    	closedir(DIR);
    	return @themes; 
	#exit 0;

}

sub get_active_theme
{
	my ( $self ) = @_;
	my $repo = $self->{repository};
	my $active_theme = $repo->get_conf( "theme");
	print "actiove theme: ".$active_theme;
}
sub allow_update
{
    my( $self ) = @_;
    return 1; 
}
sub action_update
{
    my( $self ) = @_;
    # Do stuff

}
sub allow_update_theme 
{
   my( $self ) = @_;
   return 1; 
}

sub action_update_theme
{
	my ( $self ) = @_;
	my $session = $self->{session};
	my $theme = $session->param( 'theme_select' );
	my $dest = $session->config( "config_path" )."/cfg.d/xxxx_theme_admin.pl";
	my $names = "theme";
	#my $write = $session->config->write_config( $dest, [$names], [$theme] );
        #my $conf1 = "";
        my $conf1 = <<'END';
#
# Theme Admin Theme Loader
#
# this file is automatically generated when you change theme using the Theme Admin Screen
#

END
	my $conf2 = '$c->{theme} ="'.$theme.'"'.';';

	my $conf = join "", $conf1, $conf2;
	#print $conf;
        my $write = EPrints->system->write_config_file( $dest, $conf );
	$session->reload_config;
}

sub render
{
	
	my( $self ) = @_;

	my $session = $self->{session};
	my $repo = $self->{repository};

	my @themes = &get_themes;

	&get_active_theme;
#	my $dest = $session->config( "config_path" )."/cfg.d/xxxx_theme_admin.pl";
#	my $names= "themeX";
#	my $conf = "roar";
#	my $conf = <<'END';
#
# Theme Admin Theme Loader
#
# this file is automatically generated when you change theme using the Theme Admin Screen
#
#
#$c->{theme} = 'roar';
#
#END


#	my $write = $session->config->write_config( $dest, $names, $values );
#	my $write = EPrints->system->write_config_file( $dest, $conf );


	
        #load the theme phrases
	my $file = $session->config( "config_path" )."/lang/".$session->get_lang->{id}."/phrases/docklands.xml";

	my @sections = ("colours","buttons","shadows","borders");
	
	my $dc1_id = "docklands_colour_1";	
	my $dc2_id = "docklands_colour_2";	
	my @phrasesColours = ($dc1_id,$dc2_id);

	my $btnr_id = "docklands_btn_radius";
	my @phrasesButtons = ($btnr_id); 

	my $shadow_bool_id = "docklands_shadows";
	my @phrasesShadows = ($shadow_bool_id);

	my $border_thick_id = "docklands_border_thick";
	my $border_radius_id = "docklands_border_radius";
	my @phrasesBorders = ($border_thick_id, $border_radius_id);
 

	# Create empty document
	my $page = $session->make_doc_fragment();
	my $container = $session->make_element( 'div', id=>"themeAdmin",class=>"container-fluid");
	
	my $intro = $session->make_element( 'div', id=>"themeAdminDescription", class=>"col-md-12 col-sm-12 col-xs-12");
	$intro->appendChild($self->html_phrase( "intro" ));
	$container->appendChild($intro);		
	
	#theme selection
	my $xhtml = $repo->xhtml;
	my $theme_form = $xhtml->form( "get" );# [, $action] )
	my $select = $session->make_element( 'select', name=>"theme_select" );
        foreach my $theme ( @themes )
        {
        	my $option = $session->make_element( 'option', value=>$theme);
		$option->appendChild( $session->make_text($theme));
               $select->appendChild($option);
        #        print $theme;
        }
	 my %buttons = (
                    update_theme   => "update theme",
                    _order   => [ "update_theme" ],
                    _class   => "ep_form_button_bar"
	          );
	$theme_form->appendChild($select);
	$theme_form->appendChild($session->render_action_buttons( %buttons ));
	$theme_form->appendChild( $session->render_hidden_field( "screen", "ThemeAdmin"));
	$container->appendChild($theme_form);




	# Sections of the theme
	foreach my $section ( @sections )
	{
		my $divSection = $session->make_element( 'div', id=>"docklands_$section",class=>"docklands_admin_widget col-md-12");
		my $h3 = $session->make_element( "h3" );
		$h3->appendChild( $session->make_text(ucfirst($section)));
		
		my $table = $session->make_element( "table", id=>"ep_phraseedit_table_$section",class=>"table table-condensed" );
		my $th = $session->make_element( "th" );
		$th->appendChild( $session->make_text("Field"));
		$table->appendChild($th);
		my $th = $session->make_element( "th" );
		$th->appendChild( $session->make_text("Value"));
                $table->appendChild($th);
		
		my $tr = $session->make_element( "tr" );
		my $rows = $session->make_doc_fragment;
		my @phrases;		
		given ($section){	
			when("colours") {@phrases = @phrasesColours;}
			when("buttons") {@phrases = @phrasesButtons;}
			when("shadows") {@phrases = @phrasesShadows;}
			when("borders") {@phrases = @phrasesBorders;}
		}
		
		foreach my $phraseid ( @phrases )
        	{
	                my $info = $session->get_lang->get_phrase_info( $phraseid, $session );
			$rows->appendChild( $self->render_row(
                                {
                                        phraseid => $phraseid,
                                        xml => $info->{xml},
                                        langid  => $info->{langid},
                                },
                               $section 
                        ) );
        
		}
		$table->appendChild($rows);
			
		$divSection->appendChild($h3);
		$divSection->appendChild($table);
		$container->appendChild($divSection);
	};
        my $scripts = $session->make_doc_fragment;
	my $ep_save_phrase = EPrints::Utils::js_string( $self->phrase( "save" ) );
        my $ep_reset_phrase = EPrints::Utils::js_string( $self->phrase( "reset" ) );
        my $ep_cancel_phrase = EPrints::Utils::js_string( $self->phrase( "cancel" ) );
	$scripts->appendChild( $session->make_javascript( <<EOJ ) );
var ep_phraseedit_phrases = {
	save: $ep_save_phrase,
	reset: $ep_reset_phrase,
	cancel: $ep_cancel_phrase
};
EOJ
        $container->appendChild( $scripts );

	$page->appendChild($container);

	return $page;
}

sub render_row
{
	my( $self, $phrase, $type ) = @_;

	my $session = $self->{session};
	my $phraseid = $phrase->{phraseid};
	my $src = $phrase->{src};
	my $xml = $phrase->{xml};
=pod
	
	my %seen = ($phrase->{phraseid} => 1);
	while($xml->can( "hasAttribute" ) && $xml->hasAttribute( "ref" ))
	{
		my $info = $session->get_lang->get_phrase_info( $xml->getAttribute( "ref" ), $session );
		last if !defined $info;
		last if $seen{$info->{phraseid}};
		$seen{$info->{phraseid}} = 1;
		$xml = $info->{xml};
	}
=cut
	my $string = "";
	foreach my $node ($xml->childNodes)
	{
		$string .= EPrints::XML::to_string( $node );
	}

	my( $tr, $td, $div );

	$tr = $session->make_element( "tr", class => "ep_type_$type" );

	$td = $session->make_element( "td" );
	$tr->appendChild( $td );
	$td->appendChild( $session->make_text( $phraseid ) );

	#$td = $session->make_element( "td" );
	#$tr->appendChild( $td );

	$td = $session->make_element( "td" );	
	my $div = $session->make_element( "div", id => "ep_phraseedit_$phraseid", class => "ep_phraseedit_widget", onclick => "ep_phraseedit_edit(this, ep_phraseedit_phrases);" );
	if( $xml ne $phrase->{xml} )
        {
                $div->setAttribute( class => "ep_phraseedit_widget ep_phraseedit_ref" );
        }
	$div->appendChild( $session->make_text( $string ) );
        $td->appendChild( $div );
	$tr->appendChild( $td );
	
	$td = $session->make_element( "td" );	
	if ($type eq "colours"){
		# Colour picker html5 thing
		my $colour = $session->make_text( $string );
		my $colourBlock = $session->make_element( "div", style=>"display: inline-block; width: 10px;height:10px;background-color:#$colour" );
		$td->appendChild( $colourBlock );
	}

		
		
		

	#$div->appendChild( $session->make_text( $string ) );

	#$td = $session->make_element( "td" );
	$tr->appendChild( $td );

	return $tr;
}
