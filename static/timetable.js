document.addEventListener('DOMContentLoaded', function() {
  var currentView = 'all';
  var currentFilterId = '';
  var currentFilterName = '';
  var currentClassSubject = '';
  var currentClassRooms = '';
  var currentClass = null;
  var currentTeacher = null;

  var urlParams = new URLSearchParams(window.location.search);
  currentView = urlParams.get('view') || 'all';
  currentFilterId = urlParams.get('filter_id') || '';

  var viewSelect = document.getElementById('viewSelect');
  var filterSelect = document.getElementById('filterSelect');
  var filterLabel = document.getElementById('currentFilterLabel');

  viewSelect.value = currentView;

  if (currentView !== 'all' && currentFilterId) {
    loadFilterOptions(currentView);
    filterSelect.style.display = 'inline-block';
  } else {
    filterLabel.textContent = '';
  }

  loadDropdownOptions();

  viewSelect.addEventListener('change', function() {
    var view = this.value;
    if (view === 'all') {
      filterSelect.style.display = 'none';
      filterLabel.textContent = '';
      window.location.href = '/';
    } else {
      loadFilterOptions(view);
      filterSelect.style.display = 'inline-block';
      filterSelect.value = '';
      applyFilter();
    }
  });

  filterSelect.addEventListener('change', function() {
    applyFilter();
  });

  function applyFilter() {
    var view = viewSelect.value;
    var filterId = filterSelect.value;
    if (view !== 'all' && filterId) {
      window.location.href = '/?view=' + view + '&filter_id=' + filterId;
    }
  }

  async function loadFilterOptions(type) {
    var url = type === 'class' ? '/api/classes' : '/api/teachers';
    var res = await fetch(url);
    var data = await res.json();
    if (currentView === 'all') {
      filterSelect.innerHTML = '<option value="">Select...</option>';
    }
    data.forEach(function(item) {
      var opt = document.createElement('option');
      opt.value = item.id;
      opt.textContent = item.name;
      if (item.subjectRef) opt.setAttribute('data-subject', item.subjectRef);
      if (item.roomRefs) opt.setAttribute('data-rooms', item.roomRefs.join(' '));
      filterSelect.appendChild(opt);
      if (item.id === currentFilterId) {
        currentFilterName = item.name;
        currentClassSubject = item.subjectRef || '';
        currentClassRooms = item.roomRefs ? item.roomRefs.join(' ') : '';
        currentClass = item;
      }
    });
    if (type === 'teacher' && currentFilterId) {
      data.forEach(function(item) {
        if (item.id === currentFilterId) {
          currentFilterName = item.name;
          currentTeacher = item;
        }
      });
    }
    if (currentFilterName) {
      filterLabel.textContent = currentFilterName;
      filterSelect.value = currentFilterId;
    }
  }

  async function loadDropdownOptions() {
    var promises = [
      fetch('/api/subjects'),
      fetch('/api/rooms'),
      fetch('/api/teachers'),
      fetch('/api/classes')
    ];
    var results = await Promise.all(promises);
    var subjects = await results[0].json();
    var rooms = await results[1].json();
    var profs = await results[2].json();
    var classes = await results[3].json();

    var classSelect = document.getElementById('classSelect');
    classSelect.innerHTML = '<option value="">Select class...</option>';
    classes.forEach(function(c) {
      var opt = document.createElement('option');
      opt.value = c.id;
      opt.textContent = c.name;
      opt.setAttribute('data-subject', c.subjectRef);
      opt.setAttribute('data-rooms', c.roomRefs.join(' '));
      classSelect.appendChild(opt);
    });

    var subjectSelect = document.getElementById('subjectSelect');
    subjectSelect.innerHTML = '<option value="">Select subject...</option>';
    subjects.forEach(function(s) {
      var opt = document.createElement('option');
      opt.value = s.id;
      opt.textContent = s.name;
      subjectSelect.appendChild(opt);
    });

    var roomSelect = document.getElementById('roomSelect');
    roomSelect.innerHTML = '<option value="">Select room...</option>';
    rooms.forEach(function(r) {
      var opt = document.createElement('option');
      opt.value = r.id;
      opt.textContent = r.name;
      roomSelect.appendChild(opt);
    });

    var profSelect = document.getElementById('professorSelect');
    profSelect.innerHTML = '<option value="">Select professor...</option>';
    profs.forEach(function(p) {
      var opt = document.createElement('option');
      opt.value = p.id;
      opt.textContent = p.name;
      profSelect.appendChild(opt);
    });
  }

  window.openModal = function(day, time) {
    var endTime = getEndTime(time);
    var infoText = day + ', ' + time + ' - ' + endTime;

    var classGroup = document.getElementById('classGroup');
    var subjectGroup = document.getElementById('subjectGroup');
    var roomGroup = document.getElementById('roomGroup');
    var professorGroup = document.getElementById('professorGroup');

    var classSelect = document.getElementById('classSelect');
    var subjectSelect = document.getElementById('subjectSelect');
    var roomSelect = document.getElementById('roomSelect');
    var professorSelect = document.getElementById('professorSelect');

    classSelect.value = '';
    subjectSelect.value = '';
    roomSelect.value = '';
    professorSelect.value = '';

    classGroup.classList.remove('hidden');
    subjectGroup.classList.remove('hidden');
    roomGroup.classList.remove('hidden');
    professorGroup.classList.remove('hidden');

    if (currentView === 'class' && currentFilterId) {
      classSelect.value = currentFilterId;
      classSelect.disabled = true;
      classGroup.classList.add('hidden');

      var opt = classSelect.options[classSelect.selectedIndex];
      var subj = opt ? opt.getAttribute('data-subject') : '';
      var rms = opt ? opt.getAttribute('data-rooms') : '';

      if (subj) {
        subjectSelect.value = subj;
        subjectSelect.disabled = true;
        subjectGroup.classList.remove('hidden');
      } else {
        subjectGroup.classList.add('hidden');
      }

      if (rms) {
        var firstRoom = rms.split(' ')[0];
        roomSelect.value = firstRoom;
        roomSelect.disabled = true;
        roomGroup.classList.remove('hidden');
      } else {
        roomGroup.classList.add('hidden');
      }

      professorSelect.disabled = false;
      professorGroup.classList.remove('hidden');

    } else if (currentView === 'teacher' && currentFilterId) {
      professorSelect.value = currentFilterId;
      professorSelect.disabled = true;
      professorGroup.classList.add('hidden');

      classSelect.disabled = false;
      subjectSelect.disabled = false;
      roomSelect.disabled = false;

    } else {
      classSelect.disabled = false;
      subjectSelect.disabled = false;
      roomSelect.disabled = false;
      professorSelect.disabled = false;
    }

    document.getElementById('modalInfo').textContent = infoText;
    document.getElementById('sessionModal').classList.add('active');
  };

  window.closeModal = function() {
    document.getElementById('sessionModal').classList.remove('active');
  };

  window.getEndTime = function(start) {
    var parts = start.split(':');
    var h = parseInt(parts[0], 10);
    var m = parseInt(parts[1], 10);
    var endH = h + 1;
    var hStr = endH < 10 ? '0' + endH : String(endH);
    var mStr = m < 10 ? '0' + m : String(m);
    return hStr + ':' + mStr;
  };

  window.submitSession = async function() {
    var modalInfo = document.getElementById('modalInfo').textContent;
    var parts = modalInfo.split(', ');
    var day = parts[0];
    var timeParts = parts[1].split(' - ');
    var start = timeParts[0];
    var end = timeParts[1];

    var classSelect = document.getElementById('classSelect');
    var subjectSelect = document.getElementById('subjectSelect');
    var roomSelect = document.getElementById('roomSelect');
    var professorSelect = document.getElementById('professorSelect');

    var data = {
      day: day,
      start: start,
      end: end,
      subjectRef: subjectSelect.value,
      roomRef: roomSelect.value,
      professorRef: professorSelect.value,
      classRef: classSelect.value
    };

    if (!data.subjectRef || !data.roomRef || !data.professorRef || !data.classRef) {
      showToast('Please fill all fields', 'error');
      return;
    }

    var res = await fetch('/api/sessions', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(data)
    });

    var result = await res.json();
    if (res.ok) {
      showToast('Session added successfully', 'success');
      closeModal();
      setTimeout(function() { window.location.reload(); }, 500);
    } else {
      showToast(result.message || 'Failed to add session', 'error');
    }
  };

  window.showToast = function(msg, type) {
    var toast = document.getElementById('toast');
    toast.textContent = msg;
    toast.className = 'toast ' + type;
    toast.style.display = 'block';
    setTimeout(function() { toast.style.display = 'none'; }, 3000);
  };

  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      closeModal();
    }
  });

  document.getElementById('sessionModal').addEventListener('click', function(e) {
    if (e.target === this) {
      closeModal();
    }
  });
});