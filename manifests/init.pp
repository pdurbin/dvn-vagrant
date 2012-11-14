stage { 'packages':  before  => Stage['main'] }

stage { 'downloads': before  => Stage['main'] }

stage { 'postgres':  require => Stage['main'] }

stage { 'last':      require => Stage['postgres'] }

class {
    'packages':  stage => packages;
    'downloads': stage => downloads;
    'dvn':       stage => main;
    'postgres':  stage => postgres;
    'last':      stage => last;
}
